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
class TranslationsEn extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsEn({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsEn _root = this; // ignore: unused_field

	@override 
	TranslationsEn $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsEn(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$en app = _Translations$app$en._(_root);
	@override late final _Translations$auth$en auth = _Translations$auth$en._(_root);
	@override late final _Translations$nav$en nav = _Translations$nav$en._(_root);
	@override late final _Translations$common$en common = _Translations$common$en._(_root);
	@override late final _Translations$sync$en sync = _Translations$sync$en._(_root);
	@override late final _Translations$dashboard$en dashboard = _Translations$dashboard$en._(_root);
	@override late final _Translations$projectCard$en projectCard = _Translations$projectCard$en._(_root);
	@override late final _Translations$projectModal$en projectModal = _Translations$projectModal$en._(_root);
	@override late final _Translations$participants$en participants = _Translations$participants$en._(_root);
	@override late final _Translations$participantModal$en participantModal = _Translations$participantModal$en._(_root);
	@override late final _Translations$participantCard$en participantCard = _Translations$participantCard$en._(_root);
	@override late final _Translations$gender$en gender = _Translations$gender$en._(_root);
	@override late final _Translations$roles$en roles = _Translations$roles$en._(_root);
	@override late final _Translations$status$en status = _Translations$status$en._(_root);
	@override late final _Translations$settings$en settings = _Translations$settings$en._(_root);
	@override late final _Translations$options$en options = _Translations$options$en._(_root);
	@override late final _Translations$days$en days = _Translations$days$en._(_root);
	@override late final _Translations$congregation$en congregation = _Translations$congregation$en._(_root);
	@override late final _Translations$newCongregation$en newCongregation = _Translations$newCongregation$en._(_root);
	@override late final _Translations$invite$en invite = _Translations$invite$en._(_root);
	@override late final _Translations$picker$en picker = _Translations$picker$en._(_root);
	@override late final _Translations$preview$en preview = _Translations$preview$en._(_root);
	@override late final _Translations$export$en export = _Translations$export$en._(_root);
	@override late final _Translations$projectBar$en projectBar = _Translations$projectBar$en._(_root);
	@override late final _Translations$workspace$en workspace = _Translations$workspace$en._(_root);
	@override late final _Translations$relativeTime$en relativeTime = _Translations$relativeTime$en._(_root);
}

// Path: app
class _Translations$app$en extends Translations$app$es {
	_Translations$app$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get brand => 'Agora';
	@override String get defaultProjectName => 'Program';
}

// Path: auth
class _Translations$auth$en extends Translations$auth$es {
	_Translations$auth$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override late final _Translations$auth$unlock$en unlock = _Translations$auth$unlock$en._(_root);
	@override late final _Translations$auth$create$en create = _Translations$auth$create$en._(_root);
	@override late final _Translations$auth$reset$en reset = _Translations$auth$reset$en._(_root);
	@override late final _Translations$auth$keyError$en keyError = _Translations$auth$keyError$en._(_root);
}

// Path: nav
class _Translations$nav$en extends Translations$nav$es {
	_Translations$nav$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get home => 'Home';
	@override String get participants => 'Participants';
	@override String get settings => 'Settings';
}

// Path: common
class _Translations$common$en extends Translations$common$es {
	_Translations$common$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Cancel';
	@override String get delete => 'Delete';
	@override String get close => 'Close';
	@override String get back => 'Back';
	@override String get backToPanel => 'Back to dashboard';
	@override String get reminders => 'Reminders';
	@override String get understood => 'Got it';
	@override String get saveChanges => 'Save changes';
	@override String get searchParticipant => 'Search participant…';
	@override String get removeAssignment => 'Remove assignment';
	@override String get allFeminine => 'All';
	@override String get allMasculine => 'All';
}

// Path: sync
class _Translations$sync$en extends Translations$sync$es {
	_Translations$sync$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get updating => 'Updating catalogs';
	@override String get updatingTip => 'Downloading the latest workbooks…';
	@override String get upToDate => 'Catalogs up to date';
	@override String get upToDateTip => 'Your workbooks are up to date.';
	@override String get missing => 'A workbook is missing';
	@override String get missingTip => 'The next workbook isn\'t available yet; it will be retried.';
}

// Path: dashboard
class _Translations$dashboard$en extends Translations$dashboard$es {
	_Translations$dashboard$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get greetingMorning => 'Good morning';
	@override String get greetingAfternoon => 'Good afternoon';
	@override String get greetingEvening => 'Good evening';
	@override String greetingNamed({required Object greeting, required Object name}) => '${greeting}, ${name}';
	@override String get subtitle => 'Your projects and to-dos';
	@override String get newProject => 'New project';
	@override String get allStatus => 'Any status';
	@override String get projects => 'Projects';
	@override String get reminders => 'Reminders';
	@override String get seeAll => 'See all';
}

// Path: projectCard
class _Translations$projectCard$en extends Translations$projectCard$es {
	_Translations$projectCard$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String edited({required Object label}) => 'Edited ${label}';
	@override String get editProject => 'Edit project';
}

// Path: projectModal
class _Translations$projectModal$en extends Translations$projectModal$es {
	_Translations$projectModal$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get newTitle => 'New project';
	@override String get editTitle => 'Edit project';
	@override String get desc => 'A project groups the weeks you want: a full month or a single week.';
	@override String get noNotebooks => 'No workbooks available yet.\nDownload them from the editor to create projects.';
	@override String get congregation => 'Congregation';
	@override String weeksToInclude({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: 'Weeks to include · ${n} selected',
		other: 'Weeks to include · ${n} selected',
	);
	@override String get projectName => 'Project name';
	@override String get nameHint => 'e.g. May 2026';
	@override String get fromOtherNotebook => 'From another workbook · tap to remove';
	@override String get create => 'Create project';
	@override String get deleteTitle => 'Delete project?';
	@override String deleteConfirm({required Object name}) => '"${name}" will be deleted. This action cannot be undone.';
	@override String autoName({required num n, required Object base}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${base} · ${n} week',
		other: '${base} · ${n} weeks',
	);
}

// Path: participants
class _Translations$participants$en extends Translations$participants$es {
	_Translations$participants$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Participants';
	@override String get subtitle => 'People for the assignments';
	@override String get add => 'Add participant';
	@override String get emptyNoData => 'No participants yet.\nAdd the first one with "Add participant".';
	@override String get emptyNoResults => 'No results with those filters.';
}

// Path: participantModal
class _Translations$participantModal$en extends Translations$participantModal$es {
	_Translations$participantModal$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get addTitle => 'Add participant';
	@override String get editTitle => 'Edit participant';
	@override String get desc => 'The privilege defines which parts can be assigned to them.';
	@override String get fullName => 'Full name';
	@override String get nameHint => 'e.g. Martin Salas';
	@override String get congregation => 'Congregation';
	@override String get isLabel => 'Is';
	@override String get male => 'Male';
	@override String get female => 'Female';
	@override String get privilege => 'Privilege';
	@override String get available => 'Available';
	@override String get availableDesc => 'Can receive assignments right now';
	@override String get deleteTitle => 'Delete permanently?';
	@override String deleteConfirm({required Object name}) => '${name} will be removed from the directory. This action cannot be undone. Assignments already written in programs are not affected.';
	@override String get roleDescPublisher => 'Takes part in "Apply Yourself to the Field Ministry" (everyone)';
	@override String get roleDescServant => 'Publisher + reading, prayer and some assignable parts';
	@override String get roleDescElder => 'Can receive any assignment in the program';
}

// Path: participantCard
class _Translations$participantCard$en extends Translations$participantCard$es {
	_Translations$participantCard$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get incomplete => 'Incomplete';
	@override String get genderUnspecified => 'Undefined';
}

// Path: gender
class _Translations$gender$en extends Translations$gender$es {
	_Translations$gender$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get male => 'Male';
	@override String get female => 'Female';
	@override String get unspecified => 'Unspecified';
}

// Path: roles
class _Translations$roles$en extends Translations$roles$es {
	_Translations$roles$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get elder => 'Elder';
	@override String get ministerialServant => 'Ministerial servant';
	@override String get publisher => 'Publisher';
	@override String get elderPlural => 'Elders';
	@override String get ministerialServantPlural => 'Ministerial servants';
	@override String get publisherPlural => 'Publishers';
}

// Path: status
class _Translations$status$en extends Translations$status$es {
	_Translations$status$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get draft => 'Draft';
	@override String get complete => 'Complete';
	@override String get exported => 'Exported';
	@override String get draftPlural => 'Drafts';
	@override String get completePlural => 'Complete';
	@override String get exportedPlural => 'Exported';
}

// Path: settings
class _Translations$settings$en extends Translations$settings$es {
	_Translations$settings$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Settings';
	@override String get subtitle => 'App and congregations';
	@override String get tabApp => 'App';
	@override String get tabCongregation => 'Congregation';
	@override String get appearance => 'Appearance';
	@override String get appearanceDesc => 'How the app looks on this device.';
	@override String get theme => 'Theme';
	@override String get themeDesc => 'Light, dark or follow the system';
	@override String get themeLight => 'Light';
	@override String get themeDark => 'Dark';
	@override String get themeSystem => 'System';
	@override String get general => 'General';
	@override String get generalDesc => 'Language and format.';
	@override String get appLanguage => 'App language';
	@override String get timeFormat => 'Time format';
	@override String get weekStart => 'Week starts on';
	@override String get pdfName => 'Name in PDFs';
	@override String get notificationsTitle => 'Notifications';
	@override String get notificationsDesc => 'Reminders generated by the app.';
	@override late final _Translations$settings$notif$en notif = _Translations$settings$notif$en._(_root);
	@override String get data => 'Data';
	@override String get dataDesc => 'Backup of your projects, participants and congregations. Also useful to move data between local mode and the cloud.';
	@override String get exportData => 'Export data';
	@override String get exportDataDesc => 'Generates a .jwbackup file with everything';
	@override String get export => 'Export';
	@override String get importData => 'Import data';
	@override String get importDataDesc => 'Restore from a .jwbackup file';
	@override String get import => 'Import';
	@override String get lastBackup => 'Last backup';
	@override String get noBackupsYet => 'No backups yet';
	@override String get session => 'Session';
	@override String get sessionDesc => 'You are using the app in local mode on this device.';
	@override String get localMode => 'Local mode';
	@override String get localModeDesc => 'Data lives only on this device';
}

// Path: options
class _Translations$options$en extends Translations$options$es {
	_Translations$options$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get timeFormat24 => '24-hour (18:00)';
	@override String get timeFormat12 => '12-hour (6:00 p.m.)';
	@override String get pdfNameFull => 'First and last name';
	@override String get pdfNameLastFirst => 'Last name, first name';
	@override String get pdfNameFirstOnly => 'First name only';
	@override String get meetingLangSpanish => 'Spanish';
	@override String get meetingLangSign => 'Sign language';
	@override String get meetingLangEnglish => 'English';
	@override String get accessAdmin => 'Administrator';
	@override String get accessEditor => 'Editor';
	@override String get accessReader => 'Reader';
}

// Path: days
class _Translations$days$en extends Translations$days$es {
	_Translations$days$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get monday => 'Monday';
	@override String get tuesday => 'Tuesday';
	@override String get wednesday => 'Wednesday';
	@override String get thursday => 'Thursday';
	@override String get friday => 'Friday';
	@override String get saturday => 'Saturday';
	@override String get sunday => 'Sunday';
}

// Path: congregation
class _Translations$congregation$en extends Translations$congregation$es {
	_Translations$congregation$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get dataTitle => 'Congregation details';
	@override String get dataDesc => 'Used in the header of the programs.';
	@override String get name => 'Name';
	@override String get number => 'Number';
	@override String get meetingLanguage => 'Meeting language';
	@override String get scheduleTitle => 'Meeting schedule';
	@override String get scheduleDesc => 'Each part\'s time is calculated from here.';
	@override String get weekdayDay => 'Midweek · day';
	@override String get weekdayTime => 'Midweek · time';
	@override String get weekendDay => 'Weekend · day';
	@override String get weekendTime => 'Weekend · time';
	@override String get auxRoom => 'Auxiliary classroom';
	@override String get auxRoomDesc => 'Enable a second classroom for students by default';
	@override String get usersTitle => 'Users with access';
	@override String get usersDesc => 'Who can view or edit this congregation\'s projects.';
	@override String get noUsers => 'No invited users yet.';
	@override String get inviteUser => 'Invite user';
	@override String get empty => 'No congregations yet.\nCreate the first one with "New congregation".';
	@override String get newCongregation => 'New congregation';
}

// Path: newCongregation
class _Translations$newCongregation$en extends Translations$newCongregation$es {
	_Translations$newCongregation$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'New congregation';
	@override String get desc => 'You will be its administrator. You can invite users afterwards.';
	@override String get create => 'Create congregation';
	@override String get name => 'Name';
	@override String get nameHint => 'e.g. Northern Gardens';
	@override String get number => 'Number';
	@override String get numberHint => 'e.g. 152423';
}

// Path: invite
class _Translations$invite$en extends Translations$invite$es {
	_Translations$invite$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Invite user';
	@override String get desc => 'They will receive an email invitation to access this congregation.';
	@override String get send => 'Send invitation';
	@override String get email => 'Email';
	@override String get emailHint => 'name@email.com';
	@override String get role => 'Role';
}

// Path: picker
class _Translations$picker$en extends Translations$picker$es {
	_Translations$picker$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get assign => 'Assign';
	@override String get recent => 'Recent';
	@override String get all => 'All';
	@override String noResults({required Object query}) => 'No results for “${query}”.';
	@override String addNamed({required Object query}) => 'Add “${query}”';
	@override String get addParticipant => 'Add participant';
	@override String get closeSelector => 'Close selector';
}

// Path: preview
class _Translations$preview$en extends Translations$preview$es {
	_Translations$preview$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get previewTab => 'Preview';
	@override String get assignTab => 'Assign';
	@override String get emptyHint => 'The preview will appear here.';
	@override String error({required Object error}) => 'Error generating the preview:\n${error}';
	@override String get zoomIn => 'Zoom in';
	@override String get zoomOut => 'Zoom out';
	@override String get fitPage => 'Fit whole page';
	@override String get fitWidth => 'Fit to width';
}

// Path: export
class _Translations$export$en extends Translations$export$es {
	_Translations$export$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get export => 'Export';
	@override String get exportPdf => 'Export PDF';
	@override String success({required Object path}) => 'PDF exported: ${path}';
	@override String error({required Object error}) => 'Export error: ${error}';
	@override String get currentWeek => 'Current week';
	@override String get currentWeekSub => 'A single PDF sheet';
	@override String get fullProject => 'Full project';
	@override String get fullProjectSub => 'All weeks in one PDF';
	@override String get sheets => 'Assignment slips';
	@override String get sheetsSub => 'One per assigned participant';
}

// Path: projectBar
class _Translations$projectBar$en extends Translations$projectBar$es {
	_Translations$projectBar$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String weeks({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${n} week',
		other: '${n} weeks',
	);
	@override String weekN({required Object n}) => 'Week ${n}';
	@override String get goToWeek => 'Go to week';
	@override String weekShort({required Object n}) => 'Wk ${n}';
	@override String get auxRoom => 'Auxiliary classroom';
	@override String get auxRoomDesc => 'Second classroom for students';
	@override String get circuitOverseer => 'Circuit overseer visit';
	@override String get circuitOverseerDesc => 'Replaces the Bible study with a talk';
}

// Path: workspace
class _Translations$workspace$en extends Translations$workspace$es {
	_Translations$workspace$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get sectionOpening => 'Opening';
	@override String get sectionTreasures => 'Treasures From God\'s Word';
	@override String get sectionMinistry => 'Apply Yourself to the Field Ministry';
	@override String get sectionChristianLife => 'Living as Christians';
	@override String get chairmanTitle => 'Meeting chairman';
	@override String get chairman => 'Chairman';
	@override String get allMeeting => 'Whole meeting';
	@override String get auxRoom => 'Auxiliary classroom';
	@override String get emptyTitle => 'The workbook downloads automatically.';
	@override String get emptyMessage => 'It is usually ready automatically. If it still doesn\'t appear, look for it manually.';
	@override String searchNotebook({required Object issue}) => 'Look for workbook ${issue}';
	@override String get assignee => 'Assign…';
	@override String duration({required Object n}) => '${n} min';
	@override String get songTag => 'Song';
	@override String get chairmanTag => 'Handled by the chairman';
	@override String get slotConductor => 'Conductor';
	@override String get slotReader => 'Reader';
	@override String get slotStudent => 'Student';
	@override String get slotAssistant => 'Assistant';
	@override String get slotInCharge => 'In charge';
	@override String get slotSpeaker => 'Speaker';
	@override String slotAux({required Object label}) => '${label} · Aux.';
	@override String get editTitle => 'Edit title';
	@override String get editTitleHint => 'Assignment title';
	@override String get restoreTitle => 'Reset';
}

// Path: relativeTime
class _Translations$relativeTime$en extends Translations$relativeTime$es {
	_Translations$relativeTime$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get now => 'just now';
}

// Path: auth.unlock
class _Translations$auth$unlock$en extends Translations$auth$unlock$es {
	_Translations$auth$unlock$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Unlock';
	@override String get subtitle => 'Enter your local password to open your encrypted data.';
	@override String get password => 'Password';
	@override String get button => 'Unlock';
	@override String get working => 'Decrypting…';
	@override String get wrongPassword => 'Wrong password.';
	@override String get forgot => 'Forgot your password?';
}

// Path: auth.create
class _Translations$auth$create$en extends Translations$auth$create$es {
	_Translations$auth$create$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Create your local account';
	@override String get subtitle => 'Your data is stored encrypted on this device. This password protects the encryption key.';
	@override String get migrateTitle => 'Protect your data';
	@override String get migrateSubtitle => 'This version adds a local account: create a password to protect the data already on this device.';
	@override String get password => 'Password';
	@override String get confirm => 'Confirm password';
	@override String get tooShort => 'The password must be at least 8 characters long.';
	@override String get mismatch => 'The passwords don\'t match.';
	@override String get noRecoveryWarning => 'If you forget your password there will be no way to recover your data. Keep it somewhere safe.';
	@override String get button => 'Create account';
	@override String get migrateButton => 'Protect data';
	@override String get working => 'Protecting…';
}

// Path: auth.reset
class _Translations$auth$reset$en extends Translations$auth$reset$es {
	_Translations$auth$reset$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Delete all data';
	@override String get warning => 'Without the password the information cannot be recovered: the local database and its keys will be permanently deleted and you will start over.';
	@override String get confirmPhrase => 'DELETE';
	@override String confirmHint({required Object phrase}) => 'Type ${phrase} to confirm';
	@override String get button => 'Delete everything';
}

// Path: auth.keyError
class _Translations$auth$keyError$en extends Translations$auth$keyError$es {
	_Translations$auth$keyError$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Could not access the system keychain';
	@override String get retry => 'Retry';
}

// Path: settings.notif
class _Translations$settings$notif$en extends Translations$settings$notif$es {
	_Translations$settings$notif$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get unassignedTitle => 'Unassigned parts';
	@override String get unassignedDesc => 'Warn when assignments are missing 3 days before the meeting';
	@override String get loadTitle => 'Assignment load';
	@override String get loadDesc => 'Warn if a participant has too many assignments';
	@override String get newNotebooksTitle => 'New workbooks';
	@override String get newNotebooksDesc => 'Notify when a new workbook is available';
	@override String get exportsTitle => 'Pending exports';
	@override String get exportsDesc => 'Remind to export the program before the weekend';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsEn {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.brand' => 'Agora',
			'app.defaultProjectName' => 'Program',
			'auth.unlock.title' => 'Unlock',
			'auth.unlock.subtitle' => 'Enter your local password to open your encrypted data.',
			'auth.unlock.password' => 'Password',
			'auth.unlock.button' => 'Unlock',
			'auth.unlock.working' => 'Decrypting…',
			'auth.unlock.wrongPassword' => 'Wrong password.',
			'auth.unlock.forgot' => 'Forgot your password?',
			'auth.create.title' => 'Create your local account',
			'auth.create.subtitle' => 'Your data is stored encrypted on this device. This password protects the encryption key.',
			'auth.create.migrateTitle' => 'Protect your data',
			'auth.create.migrateSubtitle' => 'This version adds a local account: create a password to protect the data already on this device.',
			'auth.create.password' => 'Password',
			'auth.create.confirm' => 'Confirm password',
			'auth.create.tooShort' => 'The password must be at least 8 characters long.',
			'auth.create.mismatch' => 'The passwords don\'t match.',
			'auth.create.noRecoveryWarning' => 'If you forget your password there will be no way to recover your data. Keep it somewhere safe.',
			'auth.create.button' => 'Create account',
			'auth.create.migrateButton' => 'Protect data',
			'auth.create.working' => 'Protecting…',
			'auth.reset.title' => 'Delete all data',
			'auth.reset.warning' => 'Without the password the information cannot be recovered: the local database and its keys will be permanently deleted and you will start over.',
			'auth.reset.confirmPhrase' => 'DELETE',
			'auth.reset.confirmHint' => ({required Object phrase}) => 'Type ${phrase} to confirm',
			'auth.reset.button' => 'Delete everything',
			'auth.keyError.title' => 'Could not access the system keychain',
			'auth.keyError.retry' => 'Retry',
			'nav.home' => 'Home',
			'nav.participants' => 'Participants',
			'nav.settings' => 'Settings',
			'common.cancel' => 'Cancel',
			'common.delete' => 'Delete',
			'common.close' => 'Close',
			'common.back' => 'Back',
			'common.backToPanel' => 'Back to dashboard',
			'common.reminders' => 'Reminders',
			'common.understood' => 'Got it',
			'common.saveChanges' => 'Save changes',
			'common.searchParticipant' => 'Search participant…',
			'common.removeAssignment' => 'Remove assignment',
			'common.allFeminine' => 'All',
			'common.allMasculine' => 'All',
			'sync.updating' => 'Updating catalogs',
			'sync.updatingTip' => 'Downloading the latest workbooks…',
			'sync.upToDate' => 'Catalogs up to date',
			'sync.upToDateTip' => 'Your workbooks are up to date.',
			'sync.missing' => 'A workbook is missing',
			'sync.missingTip' => 'The next workbook isn\'t available yet; it will be retried.',
			'dashboard.greetingMorning' => 'Good morning',
			'dashboard.greetingAfternoon' => 'Good afternoon',
			'dashboard.greetingEvening' => 'Good evening',
			'dashboard.greetingNamed' => ({required Object greeting, required Object name}) => '${greeting}, ${name}',
			'dashboard.subtitle' => 'Your projects and to-dos',
			'dashboard.newProject' => 'New project',
			'dashboard.allStatus' => 'Any status',
			'dashboard.projects' => 'Projects',
			'dashboard.reminders' => 'Reminders',
			'dashboard.seeAll' => 'See all',
			'projectCard.edited' => ({required Object label}) => 'Edited ${label}',
			'projectCard.editProject' => 'Edit project',
			'projectModal.newTitle' => 'New project',
			'projectModal.editTitle' => 'Edit project',
			'projectModal.desc' => 'A project groups the weeks you want: a full month or a single week.',
			'projectModal.noNotebooks' => 'No workbooks available yet.\nDownload them from the editor to create projects.',
			'projectModal.congregation' => 'Congregation',
			'projectModal.weeksToInclude' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: 'Weeks to include · ${n} selected', other: 'Weeks to include · ${n} selected', ), 
			'projectModal.projectName' => 'Project name',
			'projectModal.nameHint' => 'e.g. May 2026',
			'projectModal.fromOtherNotebook' => 'From another workbook · tap to remove',
			'projectModal.create' => 'Create project',
			'projectModal.deleteTitle' => 'Delete project?',
			'projectModal.deleteConfirm' => ({required Object name}) => '"${name}" will be deleted. This action cannot be undone.',
			'projectModal.autoName' => ({required num n, required Object base}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${base} · ${n} week', other: '${base} · ${n} weeks', ), 
			'participants.title' => 'Participants',
			'participants.subtitle' => 'People for the assignments',
			'participants.add' => 'Add participant',
			'participants.emptyNoData' => 'No participants yet.\nAdd the first one with "Add participant".',
			'participants.emptyNoResults' => 'No results with those filters.',
			'participantModal.addTitle' => 'Add participant',
			'participantModal.editTitle' => 'Edit participant',
			'participantModal.desc' => 'The privilege defines which parts can be assigned to them.',
			'participantModal.fullName' => 'Full name',
			'participantModal.nameHint' => 'e.g. Martin Salas',
			'participantModal.congregation' => 'Congregation',
			'participantModal.isLabel' => 'Is',
			'participantModal.male' => 'Male',
			'participantModal.female' => 'Female',
			'participantModal.privilege' => 'Privilege',
			'participantModal.available' => 'Available',
			'participantModal.availableDesc' => 'Can receive assignments right now',
			'participantModal.deleteTitle' => 'Delete permanently?',
			'participantModal.deleteConfirm' => ({required Object name}) => '${name} will be removed from the directory. This action cannot be undone. Assignments already written in programs are not affected.',
			'participantModal.roleDescPublisher' => 'Takes part in "Apply Yourself to the Field Ministry" (everyone)',
			'participantModal.roleDescServant' => 'Publisher + reading, prayer and some assignable parts',
			'participantModal.roleDescElder' => 'Can receive any assignment in the program',
			'participantCard.incomplete' => 'Incomplete',
			'participantCard.genderUnspecified' => 'Undefined',
			'gender.male' => 'Male',
			'gender.female' => 'Female',
			'gender.unspecified' => 'Unspecified',
			'roles.elder' => 'Elder',
			'roles.ministerialServant' => 'Ministerial servant',
			'roles.publisher' => 'Publisher',
			'roles.elderPlural' => 'Elders',
			'roles.ministerialServantPlural' => 'Ministerial servants',
			'roles.publisherPlural' => 'Publishers',
			'status.draft' => 'Draft',
			'status.complete' => 'Complete',
			'status.exported' => 'Exported',
			'status.draftPlural' => 'Drafts',
			'status.completePlural' => 'Complete',
			'status.exportedPlural' => 'Exported',
			'settings.title' => 'Settings',
			'settings.subtitle' => 'App and congregations',
			'settings.tabApp' => 'App',
			'settings.tabCongregation' => 'Congregation',
			'settings.appearance' => 'Appearance',
			'settings.appearanceDesc' => 'How the app looks on this device.',
			'settings.theme' => 'Theme',
			'settings.themeDesc' => 'Light, dark or follow the system',
			'settings.themeLight' => 'Light',
			'settings.themeDark' => 'Dark',
			'settings.themeSystem' => 'System',
			'settings.general' => 'General',
			'settings.generalDesc' => 'Language and format.',
			'settings.appLanguage' => 'App language',
			'settings.timeFormat' => 'Time format',
			'settings.weekStart' => 'Week starts on',
			'settings.pdfName' => 'Name in PDFs',
			'settings.notificationsTitle' => 'Notifications',
			'settings.notificationsDesc' => 'Reminders generated by the app.',
			'settings.notif.unassignedTitle' => 'Unassigned parts',
			'settings.notif.unassignedDesc' => 'Warn when assignments are missing 3 days before the meeting',
			'settings.notif.loadTitle' => 'Assignment load',
			'settings.notif.loadDesc' => 'Warn if a participant has too many assignments',
			'settings.notif.newNotebooksTitle' => 'New workbooks',
			'settings.notif.newNotebooksDesc' => 'Notify when a new workbook is available',
			'settings.notif.exportsTitle' => 'Pending exports',
			'settings.notif.exportsDesc' => 'Remind to export the program before the weekend',
			'settings.data' => 'Data',
			'settings.dataDesc' => 'Backup of your projects, participants and congregations. Also useful to move data between local mode and the cloud.',
			'settings.exportData' => 'Export data',
			'settings.exportDataDesc' => 'Generates a .jwbackup file with everything',
			'settings.export' => 'Export',
			'settings.importData' => 'Import data',
			'settings.importDataDesc' => 'Restore from a .jwbackup file',
			'settings.import' => 'Import',
			'settings.lastBackup' => 'Last backup',
			'settings.noBackupsYet' => 'No backups yet',
			'settings.session' => 'Session',
			'settings.sessionDesc' => 'You are using the app in local mode on this device.',
			'settings.localMode' => 'Local mode',
			'settings.localModeDesc' => 'Data lives only on this device',
			'options.timeFormat24' => '24-hour (18:00)',
			'options.timeFormat12' => '12-hour (6:00 p.m.)',
			'options.pdfNameFull' => 'First and last name',
			'options.pdfNameLastFirst' => 'Last name, first name',
			'options.pdfNameFirstOnly' => 'First name only',
			'options.meetingLangSpanish' => 'Spanish',
			'options.meetingLangSign' => 'Sign language',
			'options.meetingLangEnglish' => 'English',
			'options.accessAdmin' => 'Administrator',
			'options.accessEditor' => 'Editor',
			'options.accessReader' => 'Reader',
			'days.monday' => 'Monday',
			'days.tuesday' => 'Tuesday',
			'days.wednesday' => 'Wednesday',
			'days.thursday' => 'Thursday',
			'days.friday' => 'Friday',
			'days.saturday' => 'Saturday',
			'days.sunday' => 'Sunday',
			'congregation.dataTitle' => 'Congregation details',
			'congregation.dataDesc' => 'Used in the header of the programs.',
			'congregation.name' => 'Name',
			'congregation.number' => 'Number',
			'congregation.meetingLanguage' => 'Meeting language',
			'congregation.scheduleTitle' => 'Meeting schedule',
			'congregation.scheduleDesc' => 'Each part\'s time is calculated from here.',
			'congregation.weekdayDay' => 'Midweek · day',
			'congregation.weekdayTime' => 'Midweek · time',
			'congregation.weekendDay' => 'Weekend · day',
			'congregation.weekendTime' => 'Weekend · time',
			'congregation.auxRoom' => 'Auxiliary classroom',
			'congregation.auxRoomDesc' => 'Enable a second classroom for students by default',
			'congregation.usersTitle' => 'Users with access',
			'congregation.usersDesc' => 'Who can view or edit this congregation\'s projects.',
			'congregation.noUsers' => 'No invited users yet.',
			'congregation.inviteUser' => 'Invite user',
			'congregation.empty' => 'No congregations yet.\nCreate the first one with "New congregation".',
			'congregation.newCongregation' => 'New congregation',
			'newCongregation.title' => 'New congregation',
			'newCongregation.desc' => 'You will be its administrator. You can invite users afterwards.',
			'newCongregation.create' => 'Create congregation',
			'newCongregation.name' => 'Name',
			'newCongregation.nameHint' => 'e.g. Northern Gardens',
			'newCongregation.number' => 'Number',
			'newCongregation.numberHint' => 'e.g. 152423',
			'invite.title' => 'Invite user',
			'invite.desc' => 'They will receive an email invitation to access this congregation.',
			'invite.send' => 'Send invitation',
			'invite.email' => 'Email',
			'invite.emailHint' => 'name@email.com',
			'invite.role' => 'Role',
			'picker.assign' => 'Assign',
			'picker.recent' => 'Recent',
			'picker.all' => 'All',
			'picker.noResults' => ({required Object query}) => 'No results for “${query}”.',
			'picker.addNamed' => ({required Object query}) => 'Add “${query}”',
			'picker.addParticipant' => 'Add participant',
			'picker.closeSelector' => 'Close selector',
			'preview.previewTab' => 'Preview',
			'preview.assignTab' => 'Assign',
			'preview.emptyHint' => 'The preview will appear here.',
			'preview.error' => ({required Object error}) => 'Error generating the preview:\n${error}',
			'preview.zoomIn' => 'Zoom in',
			'preview.zoomOut' => 'Zoom out',
			'preview.fitPage' => 'Fit whole page',
			'preview.fitWidth' => 'Fit to width',
			'export.export' => 'Export',
			'export.exportPdf' => 'Export PDF',
			'export.success' => ({required Object path}) => 'PDF exported: ${path}',
			'export.error' => ({required Object error}) => 'Export error: ${error}',
			'export.currentWeek' => 'Current week',
			'export.currentWeekSub' => 'A single PDF sheet',
			'export.fullProject' => 'Full project',
			'export.fullProjectSub' => 'All weeks in one PDF',
			'export.sheets' => 'Assignment slips',
			'export.sheetsSub' => 'One per assigned participant',
			'projectBar.weeks' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${n} week', other: '${n} weeks', ), 
			'projectBar.weekN' => ({required Object n}) => 'Week ${n}',
			'projectBar.goToWeek' => 'Go to week',
			'projectBar.weekShort' => ({required Object n}) => 'Wk ${n}',
			'projectBar.auxRoom' => 'Auxiliary classroom',
			'projectBar.auxRoomDesc' => 'Second classroom for students',
			'projectBar.circuitOverseer' => 'Circuit overseer visit',
			'projectBar.circuitOverseerDesc' => 'Replaces the Bible study with a talk',
			'workspace.sectionOpening' => 'Opening',
			'workspace.sectionTreasures' => 'Treasures From God\'s Word',
			'workspace.sectionMinistry' => 'Apply Yourself to the Field Ministry',
			'workspace.sectionChristianLife' => 'Living as Christians',
			'workspace.chairmanTitle' => 'Meeting chairman',
			'workspace.chairman' => 'Chairman',
			'workspace.allMeeting' => 'Whole meeting',
			'workspace.auxRoom' => 'Auxiliary classroom',
			'workspace.emptyTitle' => 'The workbook downloads automatically.',
			'workspace.emptyMessage' => 'It is usually ready automatically. If it still doesn\'t appear, look for it manually.',
			'workspace.searchNotebook' => ({required Object issue}) => 'Look for workbook ${issue}',
			'workspace.assignee' => 'Assign…',
			'workspace.duration' => ({required Object n}) => '${n} min',
			'workspace.songTag' => 'Song',
			'workspace.chairmanTag' => 'Handled by the chairman',
			'workspace.slotConductor' => 'Conductor',
			'workspace.slotReader' => 'Reader',
			'workspace.slotStudent' => 'Student',
			'workspace.slotAssistant' => 'Assistant',
			'workspace.slotInCharge' => 'In charge',
			'workspace.slotSpeaker' => 'Speaker',
			'workspace.slotAux' => ({required Object label}) => '${label} · Aux.',
			'workspace.editTitle' => 'Edit title',
			'workspace.editTitleHint' => 'Assignment title',
			'workspace.restoreTitle' => 'Reset',
			'relativeTime.now' => 'just now',
			_ => null,
		};
	}
}
