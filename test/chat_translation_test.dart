import 'package:flutter_test/flutter_test.dart';

import 'package:pickdrop/features/common/chat/data/chat_service.dart';

void main() {
  test('translates english into hindi', () {
    expect(ChatService.translateTo('where are you', 'hi'), 'आप कहाँ हैं');
    expect(
      ChatService.translateTo('Please wait 5 minutes', 'hi'),
      'कृपया 5 मिनट प्रतीक्षा करें',
    );
    expect(
      ChatService.translateTo('I will call you', 'hi'),
      'मैं आपको कॉल करूँगा',
    );
  });

  test('translates hindi into english', () {
    expect(
      ChatService.translateTo('मैं पहुँच गया हूँ', 'en'),
      'I have reached',
    );
    expect(ChatService.translateTo('धन्यवाद', 'en'), 'Thank you');
    expect(
      ChatService.translateTo('मुख्य सड़क पर प्रतीक्षा करें', 'en'),
      'Wait on the main road',
    );
  });

  test('translates kannada into english', () {
    expect(ChatService.translateTo('ನಮಸ್ಕಾರ', 'en'), 'Hello');
    expect(ChatService.translateTo('ನಾನು ತಲುಪಿದ್ದೇನೆ', 'en'), 'I have reached');
    expect(
      ChatService.translateTo('ನನಗೆ 5 ನಿಮಿಷ ನೀಡಿ', 'en'),
      'Give me 5 minutes',
    );
  });

  test('keeps text when source and target language match', () {
    expect(ChatService.translateTo('where are you', 'en'), 'where are you');
    expect(ChatService.translateTo('आप कहाँ हैं', 'hi'), 'आप कहाँ हैं');
    expect(ChatService.translateTo('ನಮಸ್ಕಾರ', 'kn'), 'ನಮಸ್ಕಾರ');
  });

  test('keeps unknown phrases unchanged', () {
    expect(
      ChatService.translateTo('the ladder is heavy', 'hi'),
      'the ladder is heavy',
    );
    expect(
      ChatService.translateTo('मेरा फोन टूट गया', 'en'),
      'मेरा फोन टूट गया',
    );
    expect(ChatService.translateTo('ಬಾಗಿಲು ಮುಚ್ಚಿ', 'en'), 'ಬಾಗಿಲು ಮುಚ್ಚಿ');
  });

  test('auto translates into the viewer language', () {
    expect(ChatService.autoTranslate('thank you', 'hi'), 'धन्यवाद');
    expect(ChatService.autoTranslate('ನಮಸ್ಕಾರ', 'en'), 'Hello');
    expect(
      ChatService.autoTranslate('मैं पहुँच गया हूँ', 'kn'),
      'ನಾನು ತಲುಪಿದ್ದೇನೆ',
    );
    expect(
      ChatService.autoTranslate('Wait on the main road', 'en'),
      'Wait on the main road',
    );
  });
}
