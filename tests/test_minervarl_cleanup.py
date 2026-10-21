"""CPU checks for MinervaRL label helpers and supported launcher wiring.

Run with: python -m unittest discover -s tests -v
Training commands are captured by Bash functions; no model is loaded.
"""

import ast
import json
import os
from pathlib import Path, PurePosixPath
import shutil
import subprocess
import tempfile
import unittest

from minerva.cti_task_specs import get_task_spec
from minerva.label_details_store import LabelDetailsStore
from minerva.label_specs import extract_labels_from_truth, get_task_spec as get_label_spec, normalize_label


ROOT = Path(__file__).resolve().parents[1]
BASH = shutil.which("bash")
if BASH is None and Path("C:/Program Files/Git/bin/bash.exe").is_file():
    BASH = "C:/Program Files/Git/bin/bash.exe"


class LabelHelpersTest(unittest.TestCase):
    def test_identifier_normalization_and_deduplication(self):
        self.assertEqual(normalize_label("detection_id", " det-0001 "), "DET0001")
        self.assertEqual(normalize_label("threat_actor_name", " APT Example "), "APT Example")
        spec = get_label_spec("reward_tactic_ids")
        self.assertEqual(extract_labels_from_truth(["ta0001, TA0002", "TA0001"], spec), ["TA0001", "TA0002"])

    def test_task_alias_and_cvss_resolution(self):
        spec = get_task_spec("reward_mitigation_ids", extra_info={"task": "scenario_to_attack_mitigations"})
        self.assertEqual(spec.task_key, "scenario_to_mitigations")
        self.assertEqual(spec.entity_type, "mitigation_id")
        self.assertTrue(spec.is_multilabel)
        self.assertIsNone(get_task_spec("reward_cvss_v31").entity_type)

    def test_canonical_details_and_actor_alias_lookup(self):
        with tempfile.TemporaryDirectory() as directory:
            row = {
                "key": "threat_actor_name:Example Group", "canonical_id": "Example Group",
                "entity_type": "threat_actor_name", "name": "Example Group", "aliases": ["Example Alias"],
                "details_text": "Canonical training reference.",
            }
            Path(directory, "actors.jsonl").write_text(json.dumps(row) + "\n", encoding="utf-8")
            store = LabelDetailsStore(directory)
            self.assertEqual(store.get_details("threat_actor_name", ["example alias"]), row["details_text"])


@unittest.skipUnless(BASH, "Bash is required for launcher checks")
class TrainingLaunchersTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.checkout = Path(self.temp.name)
        self.shell_checkout = PurePosixPath(subprocess.check_output(
            [BASH, "-c", "pwd -P"], cwd=self.checkout, text=True, timeout=10,
        ).strip())
        for source in (ROOT / "rlvr/cti-scripts").rglob("*.sh"):
            target = self.checkout / source.relative_to(ROOT)
            target.parent.mkdir(parents=True, exist_ok=True)
            # Exercise the Linux scripts even when a Windows checkout uses CRLF.
            target.write_text(source.read_text(encoding="utf-8"), encoding="utf-8", newline="\n")
            target.chmod(0o755)
        for source in (ROOT / "rlvr/mydata/sft").glob("*.parquet"):
            target = self.checkout / source.relative_to(ROOT)
            target.parent.mkdir(parents=True, exist_ok=True)
            target.touch()
        model = "dataset/models/textcnn-response-only-lr6e-4-k345-f384-e300-t1024-d0p25"
        (self.checkout / model).mkdir(parents=True)
        self.bash_env = self.checkout / "capture.sh"
        self.bash_env.write_text(
            "python3() { printf '%s\\n' __TRAIN_ARGS__ \"$@\"; }\n"
            "torchrun() { printf '%s\\n' __TRAIN_ARGS__ \"$@\"; }\n",
            encoding="utf-8", newline="\n",
        )

    def capture(self, filename, *overrides, env_overrides=None):
        env = {key: value for key, value in os.environ.items() if not key.startswith(("ACRD_", "SFT_"))}
        env.update(BASH_ENV=self.bash_env.as_posix())
        env.update(env_overrides or {})
        run = subprocess.run(
            [BASH, f"rlvr/cti-scripts/{filename}", *overrides],
            cwd=self.checkout, env=env, text=True, capture_output=True, timeout=30,
        )
        self.assertEqual(run.returncode, 0, run.stderr)
        self.assertIn("__TRAIN_ARGS__\n", run.stdout)
        args = run.stdout.split("__TRAIN_ARGS__\n", 1)[1].splitlines()
        return {key.lstrip("+"): value for key, value in (arg.split("=", 1) for arg in args if "=" in arg)}

    def assert_repo_path(self, path):
        # Compare within Bash's namespace, including Git Bash's /tmp mount.
        relative = PurePosixPath(path).relative_to(self.shell_checkout)
        self.assertTrue((ROOT / relative).exists(), str(relative))
        return relative.as_posix()

    def test_all_supported_launchers_resolve_runtime_assets(self):
        launchers = sorted((ROOT / "rlvr/cti-scripts").glob("train_minerva_*.sh"))
        self.assertEqual(len(launchers), 12)
        for launcher in launchers:
            with self.subTest(launcher=launcher.name):
                args = self.capture(launcher.name)
                for key in ("data.train_files", "data.val_files"):
                    for path in ast.literal_eval(args[key]):
                        relative = self.assert_repo_path(path)
                        self.assertTrue(relative.startswith("rlvr/mydata/"), relative)
                if "noctua" in launcher.name:
                    self.assert_repo_path(args["custom_reward_function.path"])
                    self.assert_repo_path(args["data.acr.label_details_dir"])
                    self.assert_repo_path(args["data.acr.distill.filter_model"])
                    self.assertEqual(args["data.acr.ema_teacher.enabled"], "true")
                    self.assertEqual(args["data.acr.defer_generation"], "true")
                    self.assertEqual(args["data.acr.update_actor"], "false")
                    self.assertEqual(args["data.acr.distill.interval"], "10")
                    self.assertEqual(args["data.acr.distill.filter_mode"], "ml+heuristic")
                    self.assertEqual(args["data.acr.distill.lr_scale"], "0.05")
                    self.assertEqual(args["trainer.n_gpus_per_node"], "4")
                if "sft" in launcher.name:
                    self.assertEqual(args["trainer.n_gpus_per_node"], "4")

    def test_launcher_overrides_are_forwarded(self):
        args = self.capture("train_minerva_noctua_llama3b.sh", "trainer.total_training_steps=10",
                            env_overrides={"ACRD_N_GPUS_PER_NODE": "2"})
        self.assertEqual(args["trainer.total_training_steps"], "10")
        self.assertEqual(args["trainer.n_gpus_per_node"], "2")
        args = self.capture("train_minerva_sft_llama3b.sh", "trainer.total_epochs=2",
                            env_overrides={"SFT_N_GPUS_PER_NODE": "2"})
        self.assertEqual(args["trainer.total_epochs"], "2")
        self.assertEqual(args["trainer.n_gpus_per_node"], "2")


if __name__ == "__main__":
    unittest.main()
