import 'package:arin/presentation/inspire/inspiration_engagement_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('ensureLiked yalnızca bir kez ekler, toggle geri alır', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final liked = InspirationLikedNotifier(prefs);

    liked.ensureLiked('card-1');
    liked.ensureLiked('card-1');
    expect(liked.state, {'card-1'});

    liked.toggle('card-1');
    expect(liked.state, isEmpty);
  });
}
