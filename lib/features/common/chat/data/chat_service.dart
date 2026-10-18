import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.bookingId,
    required this.senderId,
    required this.senderRole,
    required this.text,
    required this.translation,
    required this.createdAt,
  });

  final String id;
  final String bookingId;
  final String senderId;
  final String senderRole;
  final String text;
  final Map<String, String> translation;
  final DateTime createdAt;

  factory ChatMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final rawTranslation = data['translation'];
    return ChatMessage(
      id: doc.id,
      bookingId: data['bookingId'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      senderRole: data['senderRole'] as String? ?? 'customer',
      text: data['text'] as String? ?? '',
      translation: rawTranslation is Map
          ? rawTranslation.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            )
          : <String, String>{},
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  String translatedInto(String language) => translation[language] ?? text;
}

class ChatService {
  ChatService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String collectionName = 'chatMessages';

  Stream<List<ChatMessage>> messages(String bookingId) {
    return _firestore
        .collection(collectionName)
        .where('bookingId', isEqualTo: bookingId)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs.map(ChatMessage.fromDoc).toList();
          items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return items;
        });
  }

  Future<void> send({
    required String bookingId,
    required String senderId,
    required String senderRole,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await _firestore.collection(collectionName).add({
      'bookingId': bookingId,
      'senderId': senderId,
      'senderRole': senderRole,
      'text': trimmed,
      'translation': {
        'hi': translateTo(trimmed, 'hi'),
        'kn': translateTo(trimmed, 'kn'),
      },
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  String translate(String text, String targetLang) {
    final dictionary = _targetDictionary(targetLang);
    if (dictionary == null || text.trim().isEmpty) return text;
    return _apply(text, dictionary);
  }

  static String translateTo(String text, String targetLang) {
    if (text.trim().isEmpty) return text;
    final source = detectLanguage(text);
    if (source == targetLang) return text;
    final dictionary =
        _pairDictionary(source, targetLang) ?? _targetDictionary(targetLang);
    if (dictionary == null) return text;
    return _apply(text, dictionary);
  }

  static String autoTranslate(String text, String viewerLang) {
    if (text.trim().isEmpty) return text;
    final source = detectLanguage(text);
    if (source == viewerLang) return text;
    final direct = translateTo(text, viewerLang);
    if (direct != text) return direct;
    if (source == 'en' || viewerLang == 'en') return text;
    final asEnglish = translateTo(text, 'en');
    if (asEnglish == text) return text;
    return translateTo(asEnglish, viewerLang);
  }

  static String detectLanguage(String text) {
    for (final rune in text.runes) {
      if (rune >= 0x0900 && rune <= 0x097F) return 'hi';
      if (rune >= 0x0C80 && rune <= 0x0CFF) return 'kn';
    }
    return 'en';
  }

  static Map<String, String>? _pairDictionary(String source, String target) {
    if (source == 'en' && target == 'hi') return _hindi;
    if (source == 'en' && target == 'kn') return _kannada;
    if (source == 'hi' && target == 'en') return _hindiToEnglish;
    if (source == 'kn' && target == 'en') return _kannadaToEnglish;
    return null;
  }

  static Map<String, String>? _targetDictionary(String targetLang) {
    if (targetLang == 'hi') return _hindi;
    if (targetLang == 'kn') return _kannada;
    return null;
  }

  static String _apply(String text, Map<String, String> dictionary) {
    final normalized = _normalize(text);
    for (final entry in dictionary.entries) {
      if (_normalize(entry.key) == normalized) return entry.value;
    }

    var result = text;
    var matched = false;
    final keys = dictionary.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final key in keys) {
      final pattern = RegExp(
        '(?<![\\p{L}\\p{M}\\p{N}_])${RegExp.escape(key)}'
        '(?![\\p{L}\\p{M}\\p{N}_])',
        caseSensitive: false,
        unicode: true,
      );
      if (!pattern.hasMatch(result)) continue;
      result = result.replaceAll(pattern, dictionary[key]!);
      matched = true;
    }
    return matched ? result : text;
  }

  static String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[.,!?;:]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static const Map<String, String> _hindi = {
    'where are you': 'आप कहाँ हैं',
    'where are you now': 'आप अभी कहाँ हैं',
    "i'm coming": 'मैं आ रहा हूँ',
    'i am coming': 'मैं आ रहा हूँ',
    'please wait 5 min': 'कृपया 5 मिनट प्रतीक्षा करें',
    'please wait 5 minutes': 'कृपया 5 मिनट प्रतीक्षा करें',
    'please wait': 'कृपया प्रतीक्षा करें',
    'reached outside': 'मैं बाहर पहुँच गया हूँ',
    'reached': 'मैं पहुँच गया हूँ',
    'call me': 'मुझे कॉल करें',
    'thank you': 'धन्यवाद',
    'thanks': 'धन्यवाद',
    'traffic': 'ट्रैफिक',
    'there is a lot of traffic': 'बहुत ट्रैफिक है',
    'traffic is heavy': 'ट्रैफिक बहुत है',
    '5 minutes away': '5 मिनट दूर',
    '10 minutes away': '10 मिनट दूर',
    'two minutes': 'दो मिनट',
    'on my way': 'मैं रास्ते में हूँ',
    'almost there': 'मैं लगभग पहुँच गया हूँ',
    'i have reached': 'मैं पहुँच गया हूँ',
    'where is the pickup': 'पिकअप कहाँ है',
    'pickup location': 'पिकअप स्थान',
    'i am at the pickup': 'मैं पिकअप पर हूँ',
    'which building': 'कौन सी बिल्डिंग',
    'please come soon': 'कृपया जल्दी आइए',
    'please come': 'कृपया आइए',
    'send me your location': 'मुझे अपना स्थान भेजें',
    'share your location': 'अपना स्थान साझा करें',
    'what is the otp': 'OTP क्या है',
    'share the otp': 'OTP साझा करें',
    'send the otp': 'OTP भेजें',
    'otp': 'OTP',
    'loading the goods': 'सामान लोड हो रहा है',
    'unloading the goods': 'सामान अनलोड हो रहा है',
    'please help with loading': 'कृपया लोडिंग में सहायता करें',
    'call support': 'सपोर्ट को कॉल करें',
    'i will be late': 'मैं देर से आऊँगा',
    'i will call you': 'मैं आपको कॉल करूँगा',
    'running late': 'मैं देर से हूँ',
    'coming now': 'अभी आ रहा हूँ',
    'wait on the main road': 'मुख्य सड़क पर प्रतीक्षा करें',
    'give me 5 minutes': 'मुझे 5 मिनट दें',
    'where should i park': 'मुझे कहाँ पार्क करना चाहिए',
    'is this the right address': 'क्या यही सही पता है',
    'how much extra': 'कितना अतिरिक्त',
    'ok': 'ठीक है',
    'okay': 'ठीक है',
    'yes': 'हाँ',
    'no': 'नहीं',
    'hello': 'नमस्ते',
    'hi': 'नमस्ते',
    'good morning': 'सुप्रभात',
    'how much time': 'कितना समय लगेगा',
    'how long will it take': 'कितना समय लगेगा',
    'is the address correct': 'क्या पता सही है',
    'i cannot find you': 'मैं आपको नहीं ढूँढ पा रहा हूँ',
    'where should i wait': 'मुझे कहाँ प्रतीक्षा करनी चाहिए',
    'please come outside': 'कृपया बाहर आइए',
    'near the gate': 'गेट के पास',
    'cancel the trip': 'यात्रा रद्द करें',
    'trip started': 'यात्रा शुरू हुई',
    'trip completed': 'यात्रा पूर्ण हुई',
    'be careful': 'सावधान रहें',
    'i am waiting here': 'मैं यहाँ प्रतीक्षा कर रहा हूँ',
    'please hurry': 'कृपया जल्दी करें',
    'cash or upi': 'नकद या UPI',
    'i am here': 'मैं यहाँ हूँ',
    'see you': 'फिर मिलेंगे',
  };

  static const Map<String, String> _kannada = {
    'where are you': 'ನೀವು ಎಲ್ಲಿದ್ದೀರಿ',
    'where are you now': 'ನೀವು ಈಗ ಎಲ್ಲಿದ್ದೀರಿ',
    "i'm coming": 'ನಾನು ಬರುತ್ತಿದ್ದೇನೆ',
    'i am coming': 'ನಾನು ಬರುತ್ತಿದ್ದೇನೆ',
    'please wait 5 min': 'ದಯವಿಟ್ಟು 5 ನಿಮಿಷ ಕಾಯಿರಿ',
    'please wait 5 minutes': 'ದಯವಿಟ್ಟು 5 ನಿಮಿಷ ಕಾಯಿರಿ',
    'please wait': 'ದಯವಿಟ್ಟು ಕಾಯಿರಿ',
    'reached outside': 'ನಾನು ಹೊರಗೆ ತಲುಪಿದ್ದೇನೆ',
    'reached': 'ನಾನು ತಲುಪಿದ್ದೇನೆ',
    'call me': 'ನನಗೆ ಕರೆ ಮಾಡಿ',
    'thank you': 'ಧನ್ಯವಾದಗಳು',
    'thanks': 'ಧನ್ಯವಾದ',
    'traffic': 'ಸಂಚಾರ ದಟ್ಟಣೆ',
    'there is a lot of traffic': 'ಬಹಳ ಟ್ರಾಫಿಕ್ ಇದೆ',
    'traffic is heavy': 'ಟ್ರಾಫಿಕ್ ಬಹಳ ಇದೆ',
    '5 minutes away': '5 ನಿಮಿಷ ದೂರದಲ್ಲಿ',
    '10 minutes away': '10 ನಿಮಿಷ ದೂರದಲ್ಲಿ',
    'two minutes': 'ಎರಡು ನಿಮಿಷ',
    'on my way': 'ನಾನು ದಾರಿಯಲ್ಲಿದ್ದೇನೆ',
    'almost there': 'ನಾನು ಬಹುತೇಕ ತಲುಪಿದ್ದೇನೆ',
    'i have reached': 'ನಾನು ತಲುಪಿದ್ದೇನೆ',
    'where is the pickup': 'ಪಿಕಪ್ ಎಲ್ಲಿದೆ',
    'pickup location': 'ಪಿಕಪ್ ಸ್ಥಳ',
    'i am at the pickup': 'ನಾನು ಪಿಕಪ್‌ನಲ್ಲಿದ್ದೇನೆ',
    'which building': 'ಯಾವ ಕಟ್ಟಡ',
    'please come soon': 'ದಯವಿಟ್ಟು ಬೇಗ ಬನ್ನಿ',
    'please come': 'ದಯವಿಟ್ಟು ಬನ್ನಿ',
    'send me your location': 'ನಿಮ್ಮ ಸ್ಥಳ ಕಳುಹಿಸಿ',
    'share your location': 'ನಿಮ್ಮ ಸ್ಥಳ ಹಂಚಿಕೊಳ್ಳಿ',
    'what is the otp': 'OTP ಏನು',
    'share the otp': 'OTP ಹಂಚಿಕೊಳ್ಳಿ',
    'send the otp': 'OTP ಕಳುಹಿಸಿ',
    'otp': 'OTP',
    'loading the goods': 'ಸರಕುಗಳನ್ನು ಲೋಡ್ ಮಾಡಲಾಗುತ್ತಿದೆ',
    'unloading the goods': 'ಸರಕುಗಳನ್ನು ಅನ್‌ಲೋಡ್ ಮಾಡಲಾಗುತ್ತಿದೆ',
    'please help with loading': 'ಲೋಡಿಂಗ್‌ನಲ್ಲಿ ಸಹಾಯ ಮಾಡಿ',
    'call support': 'ಸಪೋರ್ಟ್‌ಗೆ ಕರೆ ಮಾಡಿ',
    'i will be late': 'ನಾನು ತಡವಾಗಿ ಬರುತ್ತೇನೆ',
    'i will call you': 'ನಾನು ನಿಮಗೆ ಕರೆ ಮಾಡುತ್ತೇನೆ',
    'running late': 'ನಾನು ತಡವಾಗಿದ್ದೇನೆ',
    'coming now': 'ಈಗ ಬರುತ್ತಿದ್ದೇನೆ',
    'wait on the main road': 'ಮುಖ್ಯ ರಸ್ತೆಯಲ್ಲಿ ಕಾಯಿರಿ',
    'give me 5 minutes': 'ನನಗೆ 5 ನಿಮಿಷ ನೀಡಿ',
    'where should i park': 'ನಾನು ಎಲ್ಲಿ ಪಾರ್ಕ್ ಮಾಡಬೇಕು',
    'is this the right address': 'ಇದೇ ಸರಿಯಾದ ವಿಳಾಸವೇ',
    'how much extra': 'ಎಷ್ಟು ಹೆಚ್ಚುವರಿ',
    'ok': 'ಸರಿ',
    'okay': 'ಸರಿ',
    'yes': 'ಹೌದು',
    'no': 'ಇಲ್ಲ',
    'hello': 'ನಮಸ್ಕಾರ',
    'hi': 'ನಮಸ್ಕಾರ',
    'good morning': 'ಶುಭೋದಯ',
    'how much time': 'ಎಷ್ಟು ಸಮಯ ಬೇಕು',
    'how long will it take': 'ಎಷ್ಟು ಸಮಯ ತೆಗೆದುಕೊಳ್ಳುತ್ತದೆ',
    'is the address correct': 'ವಿಳಾಸ ಸರಿಯಾಗಿದೆಯೇ',
    'i cannot find you': 'ನಿಮ್ಮನ್ನು ಹುಡುಕಲಾಗುತ್ತಿಲ್ಲ',
    'where should i wait': 'ನಾನು ಎಲ್ಲಿ ಕಾಯಬೇಕು',
    'please come outside': 'ದಯವಿಟ್ಟು ಹೊರಗೆ ಬನ್ನಿ',
    'near the gate': 'ಗೇಟ್ ಬಳಿ',
    'cancel the trip': 'ಪ್ರಯಾಣ ರದ್ದುಮಾಡಿ',
    'trip started': 'ಪ್ರಯಾಣ ಪ್ರಾರಂಭವಾಯಿತು',
    'trip completed': 'ಪ್ರಯಾಣ ಪೂರ್ಣಗೊಂಡಿದೆ',
    'be careful': 'ಎಚ್ಚರವಾಗಿರಿ',
    'i am waiting here': 'ನಾನು ಇಲ್ಲಿ ಕಾಯುತ್ತಿದ್ದೇನೆ',
    'please hurry': 'ದಯವಿಟ್ಟು ಬೇಗ ಮಾಡಿ',
    'cash or upi': 'ನಗದು ಅಥವಾ UPI',
    'i am here': 'ನಾನು ಇಲ್ಲಿದ್ದೇನೆ',
    'see you': 'ಮತ್ತೆ ಸಿಗೋಣ',
  };

  static const Map<String, String> _hindiToEnglish = {
    'आप कहाँ हैं': 'Where are you?',
    'आप अभी कहाँ हैं': 'Where are you now?',
    'मैं आ रहा हूँ': 'I am coming',
    'कृपया 5 मिनट प्रतीक्षा करें': 'Please wait 5 minutes',
    'कृपया प्रतीक्षा करें': 'Please wait',
    'मैं बाहर पहुँच गया हूँ': 'I have reached outside',
    'मैं पहुँच गया हूँ': 'I have reached',
    'मुझे कॉल करें': 'Call me',
    'धन्यवाद': 'Thank you',
    'ट्रैफिक': 'Traffic',
    'बहुत ट्रैफिक है': 'There is a lot of traffic',
    'ट्रैफिक बहुत है': 'Traffic is heavy',
    '5 मिनट दूर': '5 minutes away',
    '10 मिनट दूर': '10 minutes away',
    'दो मिनट': 'Two minutes',
    'मैं रास्ते में हूँ': 'On my way',
    'मैं लगभग पहुँच गया हूँ': 'Almost there',
    'पिकअप कहाँ है': 'Where is the pickup?',
    'पिकअप स्थान': 'Pickup location',
    'मैं पिकअप पर हूँ': 'I am at the pickup',
    'कौन सी बिल्डिंग': 'Which building?',
    'कृपया जल्दी आइए': 'Please come soon',
    'कृपया आइए': 'Please come',
    'मुझे अपना स्थान भेजें': 'Send me your location',
    'अपना स्थान साझा करें': 'Share your location',
    'OTP क्या है': 'What is the OTP?',
    'OTP साझा करें': 'Share the OTP',
    'OTP भेजें': 'Send the OTP',
    'सामान लोड हो रहा है': 'The goods are loading',
    'सामान अनलोड हो रहा है': 'The goods are unloading',
    'कृपया लोडिंग में सहायता करें': 'Please help with loading',
    'सपोर्ट को कॉल करें': 'Call support',
    'मैं देर से आऊँगा': 'I will be late',
    'मैं आपको कॉल करूँगा': 'I will call you',
    'मैं देर से हूँ': 'I am running late',
    'अभी आ रहा हूँ': 'Coming now',
    'मुख्य सड़क पर प्रतीक्षा करें': 'Wait on the main road',
    'मुझे 5 मिनट दें': 'Give me 5 minutes',
    'मुझे कहाँ पार्क करना चाहिए': 'Where should I park?',
    'क्या यही सही पता है': 'Is this the right address?',
    'कितना अतिरिक्त': 'How much extra?',
    'ठीक है': 'Okay',
    'हाँ': 'Yes',
    'नहीं': 'No',
    'नमस्ते': 'Hello',
    'सुप्रभात': 'Good morning',
    'कितना समय लगेगा': 'How much time will it take?',
    'क्या पता सही है': 'Is the address correct?',
    'मैं आपको नहीं ढूँढ पा रहा हूँ': 'I cannot find you',
    'मुझे कहाँ प्रतीक्षा करनी चाहिए': 'Where should I wait?',
    'कृपया बाहर आइए': 'Please come outside',
    'गेट के पास': 'Near the gate',
    'यात्रा रद्द करें': 'Cancel the trip',
    'यात्रा शुरू हुई': 'Trip started',
    'यात्रा पूर्ण हुई': 'Trip completed',
    'सावधान रहें': 'Be careful',
    'मैं यहाँ प्रतीक्षा कर रहा हूँ': 'I am waiting here',
    'कृपया जल्दी करें': 'Please hurry',
    'नकद या UPI': 'Cash or UPI',
    'मैं यहाँ हूँ': 'I am here',
    'फिर मिलेंगे': 'See you',
  };

  static const Map<String, String> _kannadaToEnglish = {
    'ನೀವು ಎಲ್ಲಿದ್ದೀರಿ': 'Where are you?',
    'ನೀವು ಈಗ ಎಲ್ಲಿದ್ದೀರಿ': 'Where are you now?',
    'ನಾನು ಬರುತ್ತಿದ್ದೇನೆ': 'I am coming',
    'ದಯವಿಟ್ಟು 5 ನಿಮಿಷ ಕಾಯಿರಿ': 'Please wait 5 minutes',
    'ದಯವಿಟ್ಟು ಕಾಯಿರಿ': 'Please wait',
    'ನಾನು ಹೊರಗೆ ತಲುಪಿದ್ದೇನೆ': 'I have reached outside',
    'ನಾನು ತಲುಪಿದ್ದೇನೆ': 'I have reached',
    'ನನಗೆ ಕರೆ ಮಾಡಿ': 'Call me',
    'ಧನ್ಯವಾದಗಳು': 'Thank you',
    'ಧನ್ಯವಾದ': 'Thanks',
    'ಸಂಚಾರ ದಟ್ಟಣೆ': 'Traffic',
    'ಬಹಳ ಟ್ರಾಫಿಕ್ ಇದೆ': 'There is a lot of traffic',
    'ಟ್ರಾಫಿಕ್ ಬಹಳ ಇದೆ': 'Traffic is heavy',
    '5 ನಿಮಿಷ ದೂರದಲ್ಲಿ': '5 minutes away',
    '10 ನಿಮಿಷ ದೂರದಲ್ಲಿ': '10 minutes away',
    'ಎರಡು ನಿಮಿಷ': 'Two minutes',
    'ನಾನು ದಾರಿಯಲ್ಲಿದ್ದೇನೆ': 'On my way',
    'ನಾನು ಬಹುತೇಕ ತಲುಪಿದ್ದೇನೆ': 'Almost there',
    'ಪಿಕಪ್ ಎಲ್ಲಿದೆ': 'Where is the pickup?',
    'ಪಿಕಪ್ ಸ್ಥಳ': 'Pickup location',
    'ನಾನು ಪಿಕಪ್‌ನಲ್ಲಿದ್ದೇನೆ': 'I am at the pickup',
    'ಯಾವ ಕಟ್ಟಡ': 'Which building?',
    'ದಯವಿಟ್ಟು ಬೇಗ ಬನ್ನಿ': 'Please come soon',
    'ದಯವಿಟ್ಟು ಬನ್ನಿ': 'Please come',
    'ನಿಮ್ಮ ಸ್ಥಳ ಕಳುಹಿಸಿ': 'Send me your location',
    'ನಿಮ್ಮ ಸ್ಥಳ ಹಂಚಿಕೊಳ್ಳಿ': 'Share your location',
    'OTP ಏನು': 'What is the OTP?',
    'OTP ಹಂಚಿಕೊಳ್ಳಿ': 'Share the OTP',
    'OTP ಕಳುಹಿಸಿ': 'Send the OTP',
    'ಸರಕುಗಳನ್ನು ಲೋಡ್ ಮಾಡಲಾಗುತ್ತಿದೆ': 'The goods are loading',
    'ಸರಕುಗಳನ್ನು ಅನ್‌ಲೋಡ್ ಮಾಡಲಾಗುತ್ತಿದೆ': 'The goods are unloading',
    'ಲೋಡಿಂಗ್‌ನಲ್ಲಿ ಸಹಾಯ ಮಾಡಿ': 'Please help with loading',
    'ಸಪೋರ್ಟ್‌ಗೆ ಕರೆ ಮಾಡಿ': 'Call support',
    'ನಾನು ತಡವಾಗಿ ಬರುತ್ತೇನೆ': 'I will be late',
    'ನಾನು ನಿಮಗೆ ಕರೆ ಮಾಡುತ್ತೇನೆ': 'I will call you',
    'ನಾನು ತಡವಾಗಿದ್ದೇನೆ': 'I am running late',
    'ಈಗ ಬರುತ್ತಿದ್ದೇನೆ': 'Coming now',
    'ಮುಖ್ಯ ರಸ್ತೆಯಲ್ಲಿ ಕಾಯಿರಿ': 'Wait on the main road',
    'ನನಗೆ 5 ನಿಮಿಷ ನೀಡಿ': 'Give me 5 minutes',
    'ನಾನು ಎಲ್ಲಿ ಪಾರ್ಕ್ ಮಾಡಬೇಕು': 'Where should I park?',
    'ಇದೇ ಸರಿಯಾದ ವಿಳಾಸವೇ': 'Is this the right address?',
    'ಎಷ್ಟು ಹೆಚ್ಚುವರಿ': 'How much extra?',
    'ಸರಿ': 'Okay',
    'ಹೌದು': 'Yes',
    'ಇಲ್ಲ': 'No',
    'ನಮಸ್ಕಾರ': 'Hello',
    'ಶುಭೋದಯ': 'Good morning',
    'ಎಷ್ಟು ಸಮಯ ಬೇಕು': 'How much time will it take?',
    'ವಿಳಾಸ ಸರಿಯಾಗಿದೆಯೇ': 'Is the address correct?',
    'ನಿಮ್ಮನ್ನು ಹುಡುಕಲಾಗುತ್ತಿಲ್ಲ': 'I cannot find you',
    'ನಾನು ಎಲ್ಲಿ ಕಾಯಬೇಕು': 'Where should I wait?',
    'ದಯವಿಟ್ಟು ಹೊರಗೆ ಬನ್ನಿ': 'Please come outside',
    'ಗೇಟ್ ಬಳಿ': 'Near the gate',
    'ಪ್ರಯಾಣ ರದ್ದುಮಾಡಿ': 'Cancel the trip',
    'ಪ್ರಯಾಣ ಪ್ರಾರಂಭವಾಯಿತು': 'Trip started',
    'ಪ್ರಯಾಣ ಪೂರ್ಣಗೊಂಡಿದೆ': 'Trip completed',
    'ಎಚ್ಚರವಾಗಿರಿ': 'Be careful',
    'ನಾನು ಇಲ್ಲಿ ಕಾಯುತ್ತಿದ್ದೇನೆ': 'I am waiting here',
    'ದಯವಿಟ್ಟು ಬೇಗ ಮಾಡಿ': 'Please hurry',
    'ನಗದು ಅಥವಾ UPI': 'Cash or UPI',
    'ನಾನು ಇಲ್ಲಿದ್ದೇನೆ': 'I am here',
    'ಮತ್ತೆ ಸಿಗೋಣ': 'See you',
  };
}
