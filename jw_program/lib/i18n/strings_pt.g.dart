///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsPt extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsPt({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.pt,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <pt>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsPt _root = this; // ignore: unused_field

	@override 
	TranslationsPt $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsPt(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$nav$pt nav = _Translations$nav$pt._(_root);
	@override late final _Translations$common$pt common = _Translations$common$pt._(_root);
	@override late final _Translations$dashboard$pt dashboard = _Translations$dashboard$pt._(_root);
}

// Path: nav
class _Translations$nav$pt extends Translations$nav$es {
	_Translations$nav$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get home => 'Início';
	@override String get participants => 'Participantes';
	@override String get settings => 'Configurações';
}

// Path: common
class _Translations$common$pt extends Translations$common$es {
	_Translations$common$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Cancelar';
	@override String get delete => 'Excluir';
	@override String get close => 'Fechar';
	@override String get back => 'Voltar';
	@override String get saveChanges => 'Salvar alterações';
}

// Path: dashboard
class _Translations$dashboard$pt extends Translations$dashboard$es {
	_Translations$dashboard$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get greetingMorning => 'Bom dia';
	@override String get greetingAfternoon => 'Boa tarde';
	@override String get greetingEvening => 'Boa noite';
	@override String get subtitle => 'Seus projetos e pendências';
	@override String get newProject => 'Novo projeto';
}

/// The flat map containing all translations for locale <pt>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsPt {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'nav.home' => 'Início',
			'nav.participants' => 'Participantes',
			'nav.settings' => 'Configurações',
			'common.cancel' => 'Cancelar',
			'common.delete' => 'Excluir',
			'common.close' => 'Fechar',
			'common.back' => 'Voltar',
			'common.saveChanges' => 'Salvar alterações',
			'dashboard.greetingMorning' => 'Bom dia',
			'dashboard.greetingAfternoon' => 'Boa tarde',
			'dashboard.greetingEvening' => 'Boa noite',
			'dashboard.subtitle' => 'Seus projetos e pendências',
			'dashboard.newProject' => 'Novo projeto',
			_ => null,
		};
	}
}
