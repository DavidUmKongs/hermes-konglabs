import unittest
from unittest.mock import AsyncMock, patch
from tempfile import TemporaryDirectory
from pathlib import Path

from starlette.testclient import TestClient

import server


class _FakeProc:
    def __init__(self, stdout=b"", stderr=b"", returncode=0):
        self._stdout = stdout
        self._stderr = stderr
        self.returncode = returncode
        self.killed = False

    async def communicate(self):
        return self._stdout, self._stderr

    def kill(self):
        self.killed = True


class ChatApiTests(unittest.TestCase):
    def _client(self):
        noop = AsyncMock(return_value=None)
        patches = [
            patch.object(server.dash, "start", noop),
            patch.object(server.dash, "stop", noop),
            patch.object(server.gw, "start", noop),
            patch.object(server.gw, "stop", noop),
        ]
        for item in patches:
            item.start()
        self.addCleanup(lambda: [item.stop() for item in reversed(patches)])
        return TestClient(server.app)

    def _login(self, client: TestClient):
        response = client.post(
            "/login",
            data={"username": server.ADMIN_USERNAME, "password": server.ADMIN_PASSWORD},
            follow_redirects=False,
        )
        self.assertEqual(response.status_code, 302)

    def test_api_chat_runs_hermes_cli_and_returns_session_id(self):
        proc = _FakeProc(
            stdout=b"hello from hermes\n",
            stderr=b"\x1b[33msession_id: 20260426_demo123\x1b[0m\n",
        )
        create_proc = AsyncMock(return_value=proc)

        env_overrides = {"OPENROUTER_API_KEY": "from-env-file", "LLM_MODEL": "demo-model"}
        with self._client() as client, \
                patch("server.asyncio.create_subprocess_exec", create_proc), \
                patch("server.read_env", return_value=env_overrides):
            self._login(client)
            response = client.post(
                "/api/chat",
                json={
                    "message": "hello",
                    "resume": "sess_1",
                    "skills": ["plan", "wiki"],
                    "max_turns": 5,
                    "base_url": "should-be-ignored",
                    "api_key": "should-be-ignored",
                },
            )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            response.json(),
            {
                "ok": True,
                "response": "hello from hermes",
                "session_id": "20260426_demo123",
            },
        )
        create_proc.assert_awaited_once()
        cmd = create_proc.await_args.args
        self.assertEqual(cmd[:4], ("hermes", "--quiet", "-q", "hello"))
        self.assertIn("--resume", cmd)
        self.assertIn("sess_1", cmd)
        self.assertIn("--skills", cmd)
        self.assertIn("plan,wiki", cmd)
        self.assertIn("--max-turns", cmd)
        self.assertIn("5", cmd)
        self.assertNotIn("--max_turns", cmd)
        self.assertNotIn("--base_url", cmd)
        self.assertNotIn("--api_key", cmd)
        env = create_proc.await_args.kwargs["env"]
        self.assertEqual(env["OPENROUTER_API_KEY"], "from-env-file")
        self.assertEqual(env["LLM_MODEL"], "demo-model")
        self.assertEqual(env["HERMES_HOME"], server.HERMES_HOME)

    def test_setup_api_chat_validates_missing_message(self):
        with self._client() as client:
            self._login(client)
            response = client.post("/setup/api/chat", json={})

        self.assertEqual(response.status_code, 400)
        self.assertEqual(response.json(), {"error": "Missing message"})


class CodexProviderTests(unittest.TestCase):
    def test_write_config_yaml_prefers_codex_provider_mode(self):
        with TemporaryDirectory() as tmpdir, \
                patch.object(server, "HERMES_HOME", tmpdir), \
                patch("server._codex_runtime_base_url", return_value="https://chatgpt.com/backend-api/codex"):
            server.write_config_yaml({
                "LLM_MODEL": "gpt-5.3-codex",
                "LLM_PROVIDER_MODE": "openai-codex",
                "OPENAI_API_KEY": "stale-custom-key",
                "OPENAI_BASE_URL": "https://custom.example/v1",
            })

            text = Path(tmpdir, "config.yaml").read_text(encoding="utf-8")

        self.assertIn('provider: "openai-codex"', text)
        self.assertIn('default: "gpt-5.3-codex"', text)
        self.assertIn('base_url: "https://chatgpt.com/backend-api/codex"', text)
        self.assertIn('external_dirs:', text)
        self.assertIn('/.claude/skills/gstack', text)
        self.assertNotIn('provider: "custom"', text)

    def test_is_config_complete_requires_codex_oauth_when_codex_selected(self):
        data = {
            "LLM_MODEL": "gpt-5.3-codex",
            "LLM_PROVIDER_MODE": "openai-codex",
        }
        with patch("server._codex_oauth_configured", return_value=False):
            self.assertFalse(server.is_config_complete(data))
        with patch("server._codex_oauth_configured", return_value=True):
            self.assertTrue(server.is_config_complete(data))

    def test_selected_provider_name_falls_back_to_config_provider(self):
        data = {"LLM_MODEL": "gpt-5.3-codex"}
        with patch("server._current_model_provider_from_config", return_value="openai-codex"):
            self.assertEqual(server._selected_provider_name(data), "OpenAI Codex (OAuth)")

    def test_selected_provider_mode_prefers_current_key_over_stale_config(self):
        data = {
            "LLM_MODEL": "google/gemma-3-1b-it:free",
            "OPENROUTER_API_KEY": "sk-or-demo",
            "LLM_PROVIDER_MODE": "",
        }
        with patch("server._current_model_provider_from_config", return_value="openai-codex"):
            self.assertEqual(server._selected_provider_mode(data), "openrouter")


if __name__ == "__main__":
    unittest.main()
