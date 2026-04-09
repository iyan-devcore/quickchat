import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service to handle end-to-end encryption using X25519 and AES-GCM.
/// 
/// How it works:
/// 1. Each user has an X25519 key pair.
/// 2. Private key is stored in FlutterSecureStorage.
/// 3. Public key is shared via the backend User model.
/// 4. When Alice sends a message to Bob:
///    - Alice computes a shared secret using her Private Key and Bob's Public Key (ECDH).
///    - Alice uses the shared secret to encrypt the message with AES-GCM.
///    - Alice sends the ciphertext and nonce (IV) to the server.
/// 5. When Bob receives the message:
///    - Bob computes the same shared secret using his Private Key and Alice's Public Key.
///    - Bob decrypts the message using the shared secret and nonce.
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  final _storage = const FlutterSecureStorage();
  final _algorithm = X25519();
  final _aes = AesGcm.with256bits();

  SimpleKeyPair? _keyPair;
  String? _publicKeyBase64;

  // Cache for shared secrets to avoid re-computing for every message
  final Map<String, SecretKey> _sharedSecretCache = {};

  /// Initialize the service by loading or generating the user's key pair.
  Future<void> init() async {
    final privateKeyBase64 = await _storage.read(key: 'e2e_private_key');

    if (privateKeyBase64 != null) {
      final privateKeyBytes = base64Decode(privateKeyBase64);
      _keyPair = await _algorithm.newKeyPairFromSeed(privateKeyBytes);
    } else {
      // Generate new key pair
      _keyPair = await _algorithm.newKeyPair();
      final privateKey = await _keyPair!.extractPrivateKeyBytes();
      await _storage.write(key: 'e2e_private_key', value: base64Encode(privateKey));
    }

    final publicKey = await _keyPair!.extractPublicKey();
    _publicKeyBase64 = base64Encode(publicKey.bytes);
  }

  /// Get the user's public key as a base64 string.
  String? get publicKey => _publicKeyBase64;

  /// Get a shared secret for a specific contact's public key.
  Future<SecretKey> _getSharedSecret(String otherUserPublicKeyBase64) async {
    if (_sharedSecretCache.containsKey(otherUserPublicKeyBase64)) {
      return _sharedSecretCache[otherUserPublicKeyBase64]!;
    }

    if (_keyPair == null) throw Exception('EncryptionService not initialized');

    final otherPublicKey = SimplePublicKey(
      base64Decode(otherUserPublicKeyBase64),
      type: KeyPairType.x25519,
    );

    final sharedSecret = await _algorithm.sharedSecretKey(
      keyPair: _keyPair!,
      remotePublicKey: otherPublicKey,
    );

    _sharedSecretCache[otherUserPublicKeyBase64] = sharedSecret;
    return sharedSecret;
  }

  /// Encrypt a message for a recipient with the given public key.
  /// Returns a map with 'ciphertext', 'nonce', and 'mac' (all base64).
  Future<Map<String, String>> encryptMessage({
    required String message,
    required String recipientPublicKey,
  }) async {
    final sharedSecret = await _getSharedSecret(recipientPublicKey);
    final messageBytes = utf8.encode(message);
    
    final secretBox = await _aes.encrypt(
      messageBytes,
      secretKey: sharedSecret,
    );

    return {
      'ciphertext': base64Encode(secretBox.cipherText),
      'nonce': base64Encode(secretBox.nonce),
      'mac': base64Encode(secretBox.mac.bytes),
    };
  }

  /// Decrypt a message from a sender with the given public key.
  Future<String> decryptMessage({
    required String ciphertext,
    required String nonce,
    required String mac,
    required String senderPublicKey,
  }) async {
    try {
      final sharedSecret = await _getSharedSecret(senderPublicKey);

      final secretBox = SecretBox(
        base64Decode(ciphertext),
        nonce: base64Decode(nonce),
        mac: Mac(base64Decode(mac)),
      );

      final clearTextBytes = await _aes.decrypt(
        secretBox,
        secretKey: sharedSecret,
      );

      return utf8.decode(clearTextBytes);
    } catch (e) {
      print('Decryption error: $e');
      return '[Message Decryption Failed]';
    }
  }

  /// Generate a random symmetric key for a group.
  Future<SecretKey> generateGroupKey() async {
    return await _aes.newSecretKey();
  }

  /// Encrypt a group key with a recipient's public key (Key Wrapping).
  /// This allows only the recipient to decrypt the group key.
  Future<String> encryptGroupKey({
    required SecretKey groupKey,
    required String recipientPublicKey,
  }) async {
    // We use the same ECDH shared secret mechanism to encrypt the Group Key 
    // for each member. This is "Key Wrapping".
    final sharedSecret = await _getSharedSecret(recipientPublicKey);
    
    final groupKeyBytes = await groupKey.extractBytes();
    
    final secretBox = await _aes.encrypt(
      groupKeyBytes,
      secretKey: sharedSecret,
    );

    // Pack ciphertext, nonce, and mac into a single base64 string for simplicity
    final packed = {
      'c': base64Encode(secretBox.cipherText),
      'n': base64Encode(secretBox.nonce),
      'm': base64Encode(secretBox.mac.bytes),
    };
    return base64Encode(utf8.encode(jsonEncode(packed)));
  }

  /// Decrypt a group key that was encrypted for us.
  Future<SecretKey> decryptGroupKey({
    required String encryptedGroupKeyPacked,
    required String senderPublicKey,
  }) async {
    final decoded = jsonDecode(utf8.decode(base64Decode(encryptedGroupKeyPacked)));
    
    final sharedSecret = await _getSharedSecret(senderPublicKey);

    final secretBox = SecretBox(
      base64Decode(decoded['c']),
      nonce: base64Decode(decoded['n']),
      mac: Mac(base64Decode(decoded['m'])),
    );

    final clearTextBytes = await _aes.decrypt(
      secretBox,
      secretKey: sharedSecret,
    );

    return SecretKey(clearTextBytes);
  }

  /// Encrypt a message using a shared group key.
  Future<Map<String, String>> encryptGroupMessage({
    required String message,
    required SecretKey groupKey,
  }) async {
    final messageBytes = utf8.encode(message);
    
    final secretBox = await _aes.encrypt(
      messageBytes,
      secretKey: groupKey,
    );

    return {
      'ciphertext': base64Encode(secretBox.cipherText),
      'nonce': base64Encode(secretBox.nonce),
      'mac': base64Encode(secretBox.mac.bytes),
    };
  }

  /// Decrypt a group message using the group key.
  Future<String> decryptGroupMessage({
    required String ciphertext,
    required String nonce,
    required String mac,
    required SecretKey groupKey,
  }) async {
    try {
      final secretBox = SecretBox(
        base64Decode(ciphertext),
        nonce: base64Decode(nonce),
        mac: Mac(base64Decode(mac)),
      );

      final clearTextBytes = await _aes.decrypt(
        secretBox,
        secretKey: groupKey,
      );

      return utf8.decode(clearTextBytes);
    } catch (e) {
      print('Group decryption error: $e');
      return '[Group Message Decryption Failed]';
    }
  }

  /// Reset the service (e.g. on logout)
  void reset() {
    _sharedSecretCache.clear();
    _keyPair = null;
    _publicKeyBase64 = null;
  }
}
