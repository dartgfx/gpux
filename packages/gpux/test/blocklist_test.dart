import 'package:gpux/src/blocklist_test_helpers.dart';
import 'package:test/test.dart';

void main() {
  group('parseAdrenoVersion', () {
    final cases = [
      (input: 'Adreno (TM) 630', expected: 630),
      (input: 'Adreno (TM) 740', expected: 740),
      (input: 'Adreno (TM) 530', expected: 530),
      (input: 'Adreno 618', expected: 618),
      (input: 'Mali-G78', expected: null),
      (input: '', expected: null),
      (input: 'Some GPU without version', expected: null),
    ];
    for (final c in cases) {
      test('returns ${c.expected} for "${c.input}"', () {
        expect(parseAdrenoVersion(c.input), c.expected);
      });
    }
  });

  group('isPowerVRPreBXE', () {
    final cases = [
      (input: 'PowerVR Rogue GE8320', preBXE: true),
      (input: 'PowerVR AXE-1-16M', preBXE: true),
      (input: 'PowerVR AXM-8-256', preBXE: true),
      (input: 'PowerVR BXE-4-32', preBXE: false),
      (input: 'PowerVR BXM-8-256', preBXE: false),
      (input: 'PowerVR BXS-256-64', preBXE: false),
      (input: 'PowerVR CXT', preBXE: false),
      (input: 'PowerVR DXT', preBXE: false),
    ];
    for (final c in cases) {
      test('${c.preBXE ? "blocks" : "allows"} "${c.input}"', () {
        expect(isPowerVRPreBXE(c.input), c.preBXE);
      });
    }
  });

  group('isVulkanAtLeast', () {
    // Pack Vulkan version: major << 22 | minor << 12 | patch.
    int pack(int major, int minor, int patch) =>
        (major << 22) | (minor << 12) | patch;

    test('returns false for version 0', () {
      expect(isVulkanAtLeast(0, 1, 3, 0), isFalse);
    });

    test('exact match returns true', () {
      expect(isVulkanAtLeast(pack(1, 3, 0), 1, 3, 0), isTrue);
    });

    test('higher patch returns true', () {
      expect(isVulkanAtLeast(pack(1, 3, 5), 1, 3, 0), isTrue);
    });

    test('lower patch returns false', () {
      expect(isVulkanAtLeast(pack(1, 2, 255), 1, 3, 0), isFalse);
    });

    test('higher minor returns true', () {
      expect(isVulkanAtLeast(pack(1, 4, 0), 1, 3, 0), isTrue);
    });

    test('higher major returns true', () {
      expect(isVulkanAtLeast(pack(2, 0, 0), 1, 3, 0), isTrue);
    });

    test('lower major returns false', () {
      expect(isVulkanAtLeast(pack(0, 9, 0), 1, 0, 0), isFalse);
    });
  });
}
