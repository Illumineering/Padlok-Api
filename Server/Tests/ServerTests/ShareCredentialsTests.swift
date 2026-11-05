import Testing

@testable import Server

struct ShareCredentialsTests {
    @Test
    func base62WritesBigEndianNumbers() {
        #expect(ShareCredentials.base62([0]) == "0")
        #expect(ShareCredentials.base62([61]) == "z")
        #expect(ShareCredentials.base62([62]) == "10")
        #expect(ShareCredentials.base62([0x01, 0x00]) == "48")
        #expect(ShareCredentials.base62(Array(repeating: 0xFF, count: 16)) == "7n42DGM5Tflk9n8mt7Fhc7")
    }

    @Test
    func randomValuesAreBase62AndDistinct() {
        let values = (0..<1000).map { _ in ShareCredentials.random() }
        #expect(Set(values).count == values.count)
        #expect(values.allSatisfy { (1...22).contains($0.count) && $0.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber) } })
        #expect(values.allSatisfy(SharesRepository.isPlausible))
    }

    @Test
    func adminTokensMatchTheirHashOnly() {
        let hash = AdminToken.hash("Tk9")
        #expect(hash.count == 64)
        #expect(AdminToken.matches("Tk9", storedHash: hash))
        #expect(AdminToken.matches("Tk9", storedHash: hash.uppercased()))
        #expect(!AdminToken.matches("tk9", storedHash: hash))
        #expect(!AdminToken.matches("Tk9", storedHash: ""))
    }

    /// The Symfony server hashed with PHP's hash('sha256', …): plain hex SHA-256.
    @Test
    func hashesAreHexSHA256() {
        #expect(AdminToken.hash("abc") == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }
}
