import unittest
from zedconf.src.vsconf.core.settings import merge_settings
from zedconf.src.vsconf.core.platform import detect_os

class TestZedConf(unittest.TestCase):
    def test_detect_os(self):
        self.assertEqual(detect_os(), "linux")

    def test_merge_settings(self):
        # Test that linux settings override base settings
        result = merge_settings("linux")
        self.assertIn("terminal.integrated.defaultProfile.linux", result)
        self.assertEqual(result["terminal.integrated.defaultProfile.linux"], "toolbox")

if __name__ == "__main__":
    unittest.main()