import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLang extends ChangeNotifier {
  static final AppLang instance = AppLang._();
  AppLang._();

  String _lang = "fa";
  String get lang => _lang;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _lang = p.getString("app_lang") ?? "fa";
    notifyListeners();
  }

  Future<void> setLang(String code) async {
    _lang = code;
    final p = await SharedPreferences.getInstance();
    await p.setString("app_lang", code);
    notifyListeners();
  }

  String t(String key) {
    final m = _dict[_lang] ?? _dict["fa"]!;
    return m[key] ?? key;
  }
}

extension LangX on BuildContext {
  String Function(String) get tr => AppLang.instance.t;
}

const Map<String, Map<String, String>> _dict = {
  "fa": {"home":"خانه","search":"جستجو","fun":"سرگرمی","language":"زبان","add":"افزودن","ai":"هوش مصنوعی","manual":"دستی","all":"همه","category":"دسته‌بندی","price":"قیمت","chat":"چت","coins":"سکه","play_earn":"بازی و کسب","refresh":"نوسازی","title":"عنوان","image_url":"آدرس تصویر","currency":"ارز","save":"ذخیره"},
  "ps": {"home":"کورپاڼه","search":"لټون","fun":"لودون","language":"ژبه","add":"زیاته کړه","ai":"AI","manual":"لاسې","all":"ټول","category":"ډول","price":"بیه","chat":"چټ","coins":"سکې","play_earn":"لوبه او عاید","refresh":"نوی کول","title":"سرلیک","image_url":"د انځور پته","currency":"ارز","save":"ساتل"},
  "uz": {"home":"Bosh sahifa","search":"Qidiruv","fun":"Ko'ngilochar","language":"Til","add":"Qo'shish","ai":"AI","manual":"Qo'lda","all":"Hammasi","category":"Toifa","price":"Narx","chat":"Chat","coins":"Tanga","play_earn":"O'yin va daromad","refresh":"Yangilash","title":"Sarlavha","image_url":"Rasm URL","currency":"Valyuta","save":"Saqlash"},
  "tk": {"home":"Baş sahypa","search":"Gözleg","fun":"Güýmenje","language":"Dil","add":"Goş","ai":"AI","manual":"El bilen","all":"Hemmesi","category":"Kategoriýa","price":"Baha","chat":"Sohbet","coins":"Teňňe","play_earn":"Oýun & gazanç","refresh":"Täzelemek","title":"Ady","image_url":"Surat URL","currency":"Walýuta","save":"Sakla"},
  "tr": {"home":"Ana sayfa","search":"Ara","fun":"Eğlence","language":"Dil","add":"Ekle","manual":"Manuel","ai":"Yapay Zeka","all":"Tümü","category":"Kategori","price":"Fiyat","chat":"Sohbet","coins":"Coin","play_earn":"Oyna & Kazan","refresh":"Yenile","title":"Başlık","image_url":"Görsel URL","currency":"Para","save":"Kaydet"},
  "en": {"home":"Home","search":"Search","fun":"Fun","language":"Language","add":"Add","add_product":"Add Product","manual":"Manual","ai":"AI","all":"All","category":"Category","price":"Price","chat":"Chat","coins":"Coins","play_earn":"Play & Earn","refresh":"Refresh","title":"Title","image_url":"Image URL","currency":"Currency","save":"Save"},
  "de": {"home":"Start","search":"Suche","fun":"Spass","language":"Sprache","add":"Hinzufügen","manual":"Manuell","ai":"KI","all":"Alle","category":"Kategorie","price":"Preis","chat":"Chat","coins":"Münzen","play_earn":"Spielen & Verdienen","refresh":"Aktualisieren","title":"Titel","image_url":"Bild-URL","currency":"Währung","save":"Speichern"},
  "fr": {"home":"Accueil","search":"Recherche","fun":"Divertissement","language":"Langue","add":"Ajouter","manual":"Manuel","ai":"IA","all":"Tous","category":"Catégorie","price":"Prix","chat":"Chat","coins":"Pièces","play_earn":"Jouer & Gagner","refresh":"Actualiser","title":"Titre","image_url":"URL de l'image","currency":"Devise","save":"Enregistrer"},
  "it": {"home":"Home","search":"Cerca","fun":"Divertimento","language":"Lingua","add":"Aggiungi","manual":"Manuale","ai":"IA","all":"Tutti","category":"Categoria","price":"Prezzo","chat":"Chat","coins":"Monete","play_earn":"Gioca & Guadagna","refresh":"Aggiorna","title":"Titolo","image_url":"URL immagine","currency":"Valuta","save":"Salva"}
};
