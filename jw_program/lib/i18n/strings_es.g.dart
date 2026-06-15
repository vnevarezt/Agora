///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsEs = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.es,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <es>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final Translations$app$es app = Translations$app$es.internal(_root);
	late final Translations$nav$es nav = Translations$nav$es.internal(_root);
	late final Translations$common$es common = Translations$common$es.internal(_root);
	late final Translations$sync$es sync = Translations$sync$es.internal(_root);
	late final Translations$dashboard$es dashboard = Translations$dashboard$es.internal(_root);
	late final Translations$projectCard$es projectCard = Translations$projectCard$es.internal(_root);
	late final Translations$projectModal$es projectModal = Translations$projectModal$es.internal(_root);
	late final Translations$participants$es participants = Translations$participants$es.internal(_root);
	late final Translations$participantModal$es participantModal = Translations$participantModal$es.internal(_root);
	late final Translations$participantCard$es participantCard = Translations$participantCard$es.internal(_root);
	late final Translations$gender$es gender = Translations$gender$es.internal(_root);
	late final Translations$roles$es roles = Translations$roles$es.internal(_root);
	late final Translations$status$es status = Translations$status$es.internal(_root);
	late final Translations$settings$es settings = Translations$settings$es.internal(_root);
	late final Translations$options$es options = Translations$options$es.internal(_root);
	late final Translations$days$es days = Translations$days$es.internal(_root);
	late final Translations$congregation$es congregation = Translations$congregation$es.internal(_root);
	late final Translations$newCongregation$es newCongregation = Translations$newCongregation$es.internal(_root);
	late final Translations$invite$es invite = Translations$invite$es.internal(_root);
	late final Translations$picker$es picker = Translations$picker$es.internal(_root);
	late final Translations$preview$es preview = Translations$preview$es.internal(_root);
	late final Translations$export$es export = Translations$export$es.internal(_root);
	late final Translations$projectBar$es projectBar = Translations$projectBar$es.internal(_root);
	late final Translations$workspace$es workspace = Translations$workspace$es.internal(_root);
	late final Translations$relativeTime$es relativeTime = Translations$relativeTime$es.internal(_root);
}

// Path: app
class Translations$app$es {
	Translations$app$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Programa'
	String get brand => 'Programa';

	/// es: 'Programa'
	String get defaultProjectName => 'Programa';
}

// Path: nav
class Translations$nav$es {
	Translations$nav$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Inicio'
	String get home => 'Inicio';

	/// es: 'Participantes'
	String get participants => 'Participantes';

	/// es: 'Configuración'
	String get settings => 'Configuración';
}

// Path: common
class Translations$common$es {
	Translations$common$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Cancelar'
	String get cancel => 'Cancelar';

	/// es: 'Eliminar'
	String get delete => 'Eliminar';

	/// es: 'Cerrar'
	String get close => 'Cerrar';

	/// es: 'Volver'
	String get back => 'Volver';

	/// es: 'Volver al panel'
	String get backToPanel => 'Volver al panel';

	/// es: 'Recordatorios'
	String get reminders => 'Recordatorios';

	/// es: 'Entendido'
	String get understood => 'Entendido';

	/// es: 'Guardar cambios'
	String get saveChanges => 'Guardar cambios';

	/// es: 'Buscar participante…'
	String get searchParticipant => 'Buscar participante…';

	/// es: 'Quitar asignación'
	String get removeAssignment => 'Quitar asignación';

	/// es: 'Todas'
	String get allFeminine => 'Todas';

	/// es: 'Todos'
	String get allMasculine => 'Todos';
}

// Path: sync
class Translations$sync$es {
	Translations$sync$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Actualizando catálogos'
	String get updating => 'Actualizando catálogos';

	/// es: 'Descargando los cuadernos más recientes…'
	String get updatingTip => 'Descargando los cuadernos más recientes…';

	/// es: 'Catálogos al día'
	String get upToDate => 'Catálogos al día';

	/// es: 'Tienes los cuadernos al día.'
	String get upToDateTip => 'Tienes los cuadernos al día.';

	/// es: 'Falta un cuaderno'
	String get missing => 'Falta un cuaderno';

	/// es: 'El próximo cuaderno aún no está disponible; se reintentará.'
	String get missingTip => 'El próximo cuaderno aún no está disponible; se reintentará.';
}

// Path: dashboard
class Translations$dashboard$es {
	Translations$dashboard$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Buenos días'
	String get greetingMorning => 'Buenos días';

	/// es: 'Buenas tardes'
	String get greetingAfternoon => 'Buenas tardes';

	/// es: 'Buenas noches'
	String get greetingEvening => 'Buenas noches';

	/// es: '{greeting}, {name}'
	String greetingNamed({required Object greeting, required Object name}) => '${greeting}, ${name}';

	/// es: 'Tus proyectos y pendientes'
	String get subtitle => 'Tus proyectos y pendientes';

	/// es: 'Nuevo proyecto'
	String get newProject => 'Nuevo proyecto';

	/// es: 'Todo estado'
	String get allStatus => 'Todo estado';

	/// es: 'Proyectos'
	String get projects => 'Proyectos';

	/// es: 'Recordatorios'
	String get reminders => 'Recordatorios';

	/// es: 'Ver todo'
	String get seeAll => 'Ver todo';
}

// Path: projectCard
class Translations$projectCard$es {
	Translations$projectCard$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Editado {label}'
	String edited({required Object label}) => 'Editado ${label}';

	/// es: 'Editar proyecto'
	String get editProject => 'Editar proyecto';
}

// Path: projectModal
class Translations$projectModal$es {
	Translations$projectModal$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Nuevo proyecto'
	String get newTitle => 'Nuevo proyecto';

	/// es: 'Editar proyecto'
	String get editTitle => 'Editar proyecto';

	/// es: 'Un proyecto agrupa las semanas que quieras: un mes completo o una sola semana.'
	String get desc => 'Un proyecto agrupa las semanas que quieras: un mes completo o una sola semana.';

	/// es: 'Aún no hay cuadernos disponibles. Descárgalos desde el editor para crear proyectos.'
	String get noNotebooks => 'Aún no hay cuadernos disponibles.\nDescárgalos desde el editor para crear proyectos.';

	/// es: 'Congregación'
	String get congregation => 'Congregación';

	/// es: '(one) {Semanas a incluir · {n} seleccionada} (other) {Semanas a incluir · {n} seleccionadas}'
	String weeksToInclude({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: 'Semanas a incluir · ${n} seleccionada',
		other: 'Semanas a incluir · ${n} seleccionadas',
	);

	/// es: 'Nombre del proyecto'
	String get projectName => 'Nombre del proyecto';

	/// es: 'Ej. Mayo 2026'
	String get nameHint => 'Ej. Mayo 2026';

	/// es: 'De otro cuaderno · toca para quitar'
	String get fromOtherNotebook => 'De otro cuaderno · toca para quitar';

	/// es: 'Crear proyecto'
	String get create => 'Crear proyecto';

	/// es: '¿Eliminar proyecto?'
	String get deleteTitle => '¿Eliminar proyecto?';

	/// es: 'Se eliminará "{name}". Esta acción no se puede deshacer.'
	String deleteConfirm({required Object name}) => 'Se eliminará "${name}". Esta acción no se puede deshacer.';

	/// es: '(one) {{base} · {n} semana} (other) {{base} · {n} semanas}'
	String autoName({required num n, required Object base}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '${base} · ${n} semana',
		other: '${base} · ${n} semanas',
	);
}

// Path: participants
class Translations$participants$es {
	Translations$participants$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Participantes'
	String get title => 'Participantes';

	/// es: 'Participantes de las asignaciones'
	String get subtitle => 'Participantes de las asignaciones';

	/// es: 'Añadir participante'
	String get add => 'Añadir participante';

	/// es: 'Aún no hay participantes. Añade el primero con "Añadir participante".'
	String get emptyNoData => 'Aún no hay participantes.\nAñade el primero con "Añadir participante".';

	/// es: 'Sin resultados con esos filtros.'
	String get emptyNoResults => 'Sin resultados con esos filtros.';
}

// Path: participantModal
class Translations$participantModal$es {
	Translations$participantModal$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Añadir participante'
	String get addTitle => 'Añadir participante';

	/// es: 'Editar participante'
	String get editTitle => 'Editar participante';

	/// es: 'El privilegio define qué partes se le pueden asignar.'
	String get desc => 'El privilegio define qué partes se le pueden asignar.';

	/// es: 'Nombre completo'
	String get fullName => 'Nombre completo';

	/// es: 'Ej. Martín Salas'
	String get nameHint => 'Ej. Martín Salas';

	/// es: 'Congregación'
	String get congregation => 'Congregación';

	/// es: 'Es'
	String get isLabel => 'Es';

	/// es: 'Hombre'
	String get male => 'Hombre';

	/// es: 'Mujer'
	String get female => 'Mujer';

	/// es: 'Privilegio'
	String get privilege => 'Privilegio';

	/// es: 'Disponible'
	String get available => 'Disponible';

	/// es: 'Puede recibir asignaciones ahora mismo'
	String get availableDesc => 'Puede recibir asignaciones ahora mismo';

	/// es: '¿Eliminar definitivamente?'
	String get deleteTitle => '¿Eliminar definitivamente?';

	/// es: 'Se eliminará a {name} del directorio. Esta acción no se puede deshacer. Las asignaciones ya escritas en programas no se ven afectadas.'
	String deleteConfirm({required Object name}) => 'Se eliminará a ${name} del directorio. Esta acción no se puede deshacer. Las asignaciones ya escritas en programas no se ven afectadas.';

	/// es: 'Participa en "Seamos mejores maestros" (todos)'
	String get roleDescPublisher => 'Participa en "Seamos mejores maestros" (todos)';

	/// es: 'Publicador + lectura, oración y algunas partes asignables'
	String get roleDescServant => 'Publicador + lectura, oración y algunas partes asignables';

	/// es: 'Puede recibir cualquier asignación del programa'
	String get roleDescElder => 'Puede recibir cualquier asignación del programa';
}

// Path: participantCard
class Translations$participantCard$es {
	Translations$participantCard$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Incompleto'
	String get incomplete => 'Incompleto';

	/// es: 'Sin definir'
	String get genderUnspecified => 'Sin definir';
}

// Path: gender
class Translations$gender$es {
	Translations$gender$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Hombre'
	String get male => 'Hombre';

	/// es: 'Mujer'
	String get female => 'Mujer';

	/// es: 'No especificado'
	String get unspecified => 'No especificado';
}

// Path: roles
class Translations$roles$es {
	Translations$roles$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Anciano'
	String get elder => 'Anciano';

	/// es: 'Siervo ministerial'
	String get ministerialServant => 'Siervo ministerial';

	/// es: 'Publicador'
	String get publisher => 'Publicador';

	/// es: 'Ancianos'
	String get elderPlural => 'Ancianos';

	/// es: 'Siervos ministeriales'
	String get ministerialServantPlural => 'Siervos ministeriales';

	/// es: 'Publicadores'
	String get publisherPlural => 'Publicadores';
}

// Path: status
class Translations$status$es {
	Translations$status$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Borrador'
	String get draft => 'Borrador';

	/// es: 'Completo'
	String get complete => 'Completo';

	/// es: 'Exportado'
	String get exported => 'Exportado';

	/// es: 'Borradores'
	String get draftPlural => 'Borradores';

	/// es: 'Completos'
	String get completePlural => 'Completos';

	/// es: 'Exportados'
	String get exportedPlural => 'Exportados';
}

// Path: settings
class Translations$settings$es {
	Translations$settings$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Configuración'
	String get title => 'Configuración';

	/// es: 'Aplicación y congregaciones'
	String get subtitle => 'Aplicación y congregaciones';

	/// es: 'Aplicación'
	String get tabApp => 'Aplicación';

	/// es: 'Congregación'
	String get tabCongregation => 'Congregación';

	/// es: 'Apariencia'
	String get appearance => 'Apariencia';

	/// es: 'Cómo se ve la aplicación en este dispositivo.'
	String get appearanceDesc => 'Cómo se ve la aplicación en este dispositivo.';

	/// es: 'Tema'
	String get theme => 'Tema';

	/// es: 'Claro, oscuro o según el sistema'
	String get themeDesc => 'Claro, oscuro o según el sistema';

	/// es: 'Claro'
	String get themeLight => 'Claro';

	/// es: 'Oscuro'
	String get themeDark => 'Oscuro';

	/// es: 'Sistema'
	String get themeSystem => 'Sistema';

	/// es: 'General'
	String get general => 'General';

	/// es: 'Idioma y formato.'
	String get generalDesc => 'Idioma y formato.';

	/// es: 'Idioma de la app'
	String get appLanguage => 'Idioma de la app';

	/// es: 'Formato de hora'
	String get timeFormat => 'Formato de hora';

	/// es: 'Inicio de semana'
	String get weekStart => 'Inicio de semana';

	/// es: 'Nombre en los PDF'
	String get pdfName => 'Nombre en los PDF';

	/// es: 'Notificaciones'
	String get notificationsTitle => 'Notificaciones';

	/// es: 'Recordatorios que genera la app.'
	String get notificationsDesc => 'Recordatorios que genera la app.';

	late final Translations$settings$notif$es notif = Translations$settings$notif$es.internal(_root);

	/// es: 'Datos'
	String get data => 'Datos';

	/// es: 'Copia de seguridad de tus proyectos, participantes y congregaciones. Útil también para mover datos entre el modo local y la nube.'
	String get dataDesc => 'Copia de seguridad de tus proyectos, participantes y congregaciones. Útil también para mover datos entre el modo local y la nube.';

	/// es: 'Exportar datos'
	String get exportData => 'Exportar datos';

	/// es: 'Genera un archivo .jwbackup con todo'
	String get exportDataDesc => 'Genera un archivo .jwbackup con todo';

	/// es: 'Exportar'
	String get export => 'Exportar';

	/// es: 'Importar datos'
	String get importData => 'Importar datos';

	/// es: 'Restaura desde un archivo .jwbackup'
	String get importDataDesc => 'Restaura desde un archivo .jwbackup';

	/// es: 'Importar'
	String get import => 'Importar';

	/// es: 'Última copia'
	String get lastBackup => 'Última copia';

	/// es: 'Sin copias todavía'
	String get noBackupsYet => 'Sin copias todavía';

	/// es: 'Sesión'
	String get session => 'Sesión';

	/// es: 'Estás usando la app en modo local en este dispositivo.'
	String get sessionDesc => 'Estás usando la app en modo local en este dispositivo.';

	/// es: 'Modo local'
	String get localMode => 'Modo local';

	/// es: 'Los datos viven solo en este dispositivo'
	String get localModeDesc => 'Los datos viven solo en este dispositivo';
}

// Path: options
class Translations$options$es {
	Translations$options$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: '24 horas (18:00)'
	String get timeFormat24 => '24 horas (18:00)';

	/// es: '12 horas (6:00 p. m.)'
	String get timeFormat12 => '12 horas (6:00 p. m.)';

	/// es: 'Nombre y apellido'
	String get pdfNameFull => 'Nombre y apellido';

	/// es: 'Apellido, nombre'
	String get pdfNameLastFirst => 'Apellido, nombre';

	/// es: 'Solo nombre'
	String get pdfNameFirstOnly => 'Solo nombre';

	/// es: 'Español'
	String get meetingLangSpanish => 'Español';

	/// es: 'Lengua de señas'
	String get meetingLangSign => 'Lengua de señas';

	/// es: 'English'
	String get meetingLangEnglish => 'English';

	/// es: 'Administrador'
	String get accessAdmin => 'Administrador';

	/// es: 'Editor'
	String get accessEditor => 'Editor';

	/// es: 'Lector'
	String get accessReader => 'Lector';
}

// Path: days
class Translations$days$es {
	Translations$days$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Lunes'
	String get monday => 'Lunes';

	/// es: 'Martes'
	String get tuesday => 'Martes';

	/// es: 'Miércoles'
	String get wednesday => 'Miércoles';

	/// es: 'Jueves'
	String get thursday => 'Jueves';

	/// es: 'Viernes'
	String get friday => 'Viernes';

	/// es: 'Sábado'
	String get saturday => 'Sábado';

	/// es: 'Domingo'
	String get sunday => 'Domingo';
}

// Path: congregation
class Translations$congregation$es {
	Translations$congregation$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Datos de la congregación'
	String get dataTitle => 'Datos de la congregación';

	/// es: 'Se usan en el encabezado de los programas.'
	String get dataDesc => 'Se usan en el encabezado de los programas.';

	/// es: 'Nombre'
	String get name => 'Nombre';

	/// es: 'Número'
	String get number => 'Número';

	/// es: 'Idioma de la reunión'
	String get meetingLanguage => 'Idioma de la reunión';

	/// es: 'Horarios de reunión'
	String get scheduleTitle => 'Horarios de reunión';

	/// es: 'Las horas de cada parte se calculan a partir de aquí.'
	String get scheduleDesc => 'Las horas de cada parte se calculan a partir de aquí.';

	/// es: 'Entre semana · día'
	String get weekdayDay => 'Entre semana · día';

	/// es: 'Entre semana · hora'
	String get weekdayTime => 'Entre semana · hora';

	/// es: 'Fin de semana · día'
	String get weekendDay => 'Fin de semana · día';

	/// es: 'Fin de semana · hora'
	String get weekendTime => 'Fin de semana · hora';

	/// es: 'Sala auxiliar'
	String get auxRoom => 'Sala auxiliar';

	/// es: 'Activa una segunda sala para estudiantes por defecto'
	String get auxRoomDesc => 'Activa una segunda sala para estudiantes por defecto';

	/// es: 'Usuarios con acceso'
	String get usersTitle => 'Usuarios con acceso';

	/// es: 'Quién puede ver o editar los proyectos de esta congregación.'
	String get usersDesc => 'Quién puede ver o editar los proyectos de esta congregación.';

	/// es: 'Aún no hay usuarios invitados.'
	String get noUsers => 'Aún no hay usuarios invitados.';

	/// es: 'Invitar usuario'
	String get inviteUser => 'Invitar usuario';

	/// es: 'Aún no hay congregaciones. Crea la primera con "Nueva congregación".'
	String get empty => 'Aún no hay congregaciones.\nCrea la primera con "Nueva congregación".';

	/// es: 'Nueva congregación'
	String get newCongregation => 'Nueva congregación';
}

// Path: newCongregation
class Translations$newCongregation$es {
	Translations$newCongregation$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Nueva congregación'
	String get title => 'Nueva congregación';

	/// es: 'Serás su administrador. Después podrás invitar usuarios.'
	String get desc => 'Serás su administrador. Después podrás invitar usuarios.';

	/// es: 'Crear congregación'
	String get create => 'Crear congregación';

	/// es: 'Nombre'
	String get name => 'Nombre';

	/// es: 'Ej. Jardines del Norte'
	String get nameHint => 'Ej. Jardines del Norte';

	/// es: 'Número'
	String get number => 'Número';

	/// es: 'Ej. 152423'
	String get numberHint => 'Ej. 152423';
}

// Path: invite
class Translations$invite$es {
	Translations$invite$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Invitar usuario'
	String get title => 'Invitar usuario';

	/// es: 'Le llegará una invitación por correo para acceder a esta congregación.'
	String get desc => 'Le llegará una invitación por correo para acceder a esta congregación.';

	/// es: 'Enviar invitación'
	String get send => 'Enviar invitación';

	/// es: 'Correo electrónico'
	String get email => 'Correo electrónico';

	/// es: 'nombre@correo.com'
	String get emailHint => 'nombre@correo.com';

	/// es: 'Rol'
	String get role => 'Rol';
}

// Path: picker
class Translations$picker$es {
	Translations$picker$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Asignar'
	String get assign => 'Asignar';

	/// es: 'Recientes'
	String get recent => 'Recientes';

	/// es: 'Todos'
	String get all => 'Todos';

	/// es: 'Sin resultados para “{query}”.'
	String noResults({required Object query}) => 'Sin resultados para “${query}”.';

	/// es: 'Añadir “{query}”'
	String addNamed({required Object query}) => 'Añadir “${query}”';

	/// es: 'Añadir participante'
	String get addParticipant => 'Añadir participante';

	/// es: 'Cerrar selector'
	String get closeSelector => 'Cerrar selector';
}

// Path: preview
class Translations$preview$es {
	Translations$preview$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Vista previa'
	String get previewTab => 'Vista previa';

	/// es: 'Asignar'
	String get assignTab => 'Asignar';

	/// es: 'La vista previa aparecerá aquí.'
	String get emptyHint => 'La vista previa aparecerá aquí.';

	/// es: 'Error al generar la vista previa: {error}'
	String error({required Object error}) => 'Error al generar la vista previa:\n${error}';

	/// es: 'Acercar'
	String get zoomIn => 'Acercar';

	/// es: 'Alejar'
	String get zoomOut => 'Alejar';

	/// es: 'Ver hoja completa'
	String get fitPage => 'Ver hoja completa';

	/// es: 'Ajustar al ancho'
	String get fitWidth => 'Ajustar al ancho';
}

// Path: export
class Translations$export$es {
	Translations$export$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Exportar'
	String get export => 'Exportar';

	/// es: 'Exportar PDF'
	String get exportPdf => 'Exportar PDF';

	/// es: 'PDF exportado: {path}'
	String success({required Object path}) => 'PDF exportado: ${path}';

	/// es: 'Error al exportar: {error}'
	String error({required Object error}) => 'Error al exportar: ${error}';

	/// es: 'Semana actual'
	String get currentWeek => 'Semana actual';

	/// es: 'Una hoja PDF'
	String get currentWeekSub => 'Una hoja PDF';

	/// es: 'Proyecto completo'
	String get fullProject => 'Proyecto completo';

	/// es: 'Todas las semanas en un PDF'
	String get fullProjectSub => 'Todas las semanas en un PDF';

	/// es: 'Hojas de participación'
	String get sheets => 'Hojas de participación';

	/// es: 'Una por participante asignado'
	String get sheetsSub => 'Una por participante asignado';
}

// Path: projectBar
class Translations$projectBar$es {
	Translations$projectBar$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: '(one) {{n} semana} (other) {{n} semanas}'
	String weeks({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '${n} semana',
		other: '${n} semanas',
	);

	/// es: 'Semana {n}'
	String weekN({required Object n}) => 'Semana ${n}';

	/// es: 'Ir a la semana'
	String get goToWeek => 'Ir a la semana';

	/// es: 'Sem {n}'
	String weekShort({required Object n}) => 'Sem ${n}';

	/// es: 'Sala auxiliar'
	String get auxRoom => 'Sala auxiliar';

	/// es: 'Segunda sala para estudiantes'
	String get auxRoomDesc => 'Segunda sala para estudiantes';
}

// Path: workspace
class Translations$workspace$es {
	Translations$workspace$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Apertura'
	String get sectionOpening => 'Apertura';

	/// es: 'Tesoros de la Biblia'
	String get sectionTreasures => 'Tesoros de la Biblia';

	/// es: 'Seamos mejores maestros'
	String get sectionMinistry => 'Seamos mejores maestros';

	/// es: 'Nuestra vida cristiana'
	String get sectionChristianLife => 'Nuestra vida cristiana';

	/// es: 'Presidente de la reunión'
	String get chairmanTitle => 'Presidente de la reunión';

	/// es: 'Presidente'
	String get chairman => 'Presidente';

	/// es: 'Toda la reunión'
	String get allMeeting => 'Toda la reunión';

	/// es: 'Sala auxiliar'
	String get auxRoom => 'Sala auxiliar';

	/// es: 'El cuaderno se descarga solo.'
	String get emptyTitle => 'El cuaderno se descarga solo.';

	/// es: 'Normalmente está listo automáticamente. Si aún no aparece, búscalo manualmente.'
	String get emptyMessage => 'Normalmente está listo automáticamente. Si aún no aparece, búscalo manualmente.';

	/// es: 'Buscar cuaderno {issue}'
	String searchNotebook({required Object issue}) => 'Buscar cuaderno ${issue}';

	/// es: 'Asignar…'
	String get assignee => 'Asignar…';

	/// es: '{n} min'
	String duration({required Object n}) => '${n} min';

	/// es: 'Cántico'
	String get songTag => 'Cántico';

	/// es: 'A cargo del presidente'
	String get chairmanTag => 'A cargo del presidente';

	/// es: 'Conductor'
	String get slotConductor => 'Conductor';

	/// es: 'Lector'
	String get slotReader => 'Lector';

	/// es: 'Estudiante'
	String get slotStudent => 'Estudiante';

	/// es: 'Ayudante'
	String get slotAssistant => 'Ayudante';

	/// es: 'Encargado'
	String get slotInCharge => 'Encargado';

	/// es: '{label} · Aux.'
	String slotAux({required Object label}) => '${label} · Aux.';
}

// Path: relativeTime
class Translations$relativeTime$es {
	Translations$relativeTime$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'ahora mismo'
	String get now => 'ahora mismo';
}

// Path: settings.notif
class Translations$settings$notif$es {
	Translations$settings$notif$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Partes sin asignar'
	String get unassignedTitle => 'Partes sin asignar';

	/// es: 'Avisar cuando falten asignaciones a 3 días de la reunión'
	String get unassignedDesc => 'Avisar cuando falten asignaciones a 3 días de la reunión';

	/// es: 'Carga de asignaciones'
	String get loadTitle => 'Carga de asignaciones';

	/// es: 'Avisar si un participante acumula muchas asignaciones'
	String get loadDesc => 'Avisar si un participante acumula muchas asignaciones';

	/// es: 'Nuevos cuadernos'
	String get newNotebooksTitle => 'Nuevos cuadernos';

	/// es: 'Avisar cuando haya un nuevo cuaderno disponible'
	String get newNotebooksDesc => 'Avisar cuando haya un nuevo cuaderno disponible';

	/// es: 'Exportaciones pendientes'
	String get exportsTitle => 'Exportaciones pendientes';

	/// es: 'Recordar exportar el programa antes del fin de semana'
	String get exportsDesc => 'Recordar exportar el programa antes del fin de semana';
}

/// The flat map containing all translations for locale <es>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.brand' => 'Programa',
			'app.defaultProjectName' => 'Programa',
			'nav.home' => 'Inicio',
			'nav.participants' => 'Participantes',
			'nav.settings' => 'Configuración',
			'common.cancel' => 'Cancelar',
			'common.delete' => 'Eliminar',
			'common.close' => 'Cerrar',
			'common.back' => 'Volver',
			'common.backToPanel' => 'Volver al panel',
			'common.reminders' => 'Recordatorios',
			'common.understood' => 'Entendido',
			'common.saveChanges' => 'Guardar cambios',
			'common.searchParticipant' => 'Buscar participante…',
			'common.removeAssignment' => 'Quitar asignación',
			'common.allFeminine' => 'Todas',
			'common.allMasculine' => 'Todos',
			'sync.updating' => 'Actualizando catálogos',
			'sync.updatingTip' => 'Descargando los cuadernos más recientes…',
			'sync.upToDate' => 'Catálogos al día',
			'sync.upToDateTip' => 'Tienes los cuadernos al día.',
			'sync.missing' => 'Falta un cuaderno',
			'sync.missingTip' => 'El próximo cuaderno aún no está disponible; se reintentará.',
			'dashboard.greetingMorning' => 'Buenos días',
			'dashboard.greetingAfternoon' => 'Buenas tardes',
			'dashboard.greetingEvening' => 'Buenas noches',
			'dashboard.greetingNamed' => ({required Object greeting, required Object name}) => '${greeting}, ${name}',
			'dashboard.subtitle' => 'Tus proyectos y pendientes',
			'dashboard.newProject' => 'Nuevo proyecto',
			'dashboard.allStatus' => 'Todo estado',
			'dashboard.projects' => 'Proyectos',
			'dashboard.reminders' => 'Recordatorios',
			'dashboard.seeAll' => 'Ver todo',
			'projectCard.edited' => ({required Object label}) => 'Editado ${label}',
			'projectCard.editProject' => 'Editar proyecto',
			'projectModal.newTitle' => 'Nuevo proyecto',
			'projectModal.editTitle' => 'Editar proyecto',
			'projectModal.desc' => 'Un proyecto agrupa las semanas que quieras: un mes completo o una sola semana.',
			'projectModal.noNotebooks' => 'Aún no hay cuadernos disponibles.\nDescárgalos desde el editor para crear proyectos.',
			'projectModal.congregation' => 'Congregación',
			'projectModal.weeksToInclude' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: 'Semanas a incluir · ${n} seleccionada', other: 'Semanas a incluir · ${n} seleccionadas', ), 
			'projectModal.projectName' => 'Nombre del proyecto',
			'projectModal.nameHint' => 'Ej. Mayo 2026',
			'projectModal.fromOtherNotebook' => 'De otro cuaderno · toca para quitar',
			'projectModal.create' => 'Crear proyecto',
			'projectModal.deleteTitle' => '¿Eliminar proyecto?',
			'projectModal.deleteConfirm' => ({required Object name}) => 'Se eliminará "${name}". Esta acción no se puede deshacer.',
			'projectModal.autoName' => ({required num n, required Object base}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '${base} · ${n} semana', other: '${base} · ${n} semanas', ), 
			'participants.title' => 'Participantes',
			'participants.subtitle' => 'Participantes de las asignaciones',
			'participants.add' => 'Añadir participante',
			'participants.emptyNoData' => 'Aún no hay participantes.\nAñade el primero con "Añadir participante".',
			'participants.emptyNoResults' => 'Sin resultados con esos filtros.',
			'participantModal.addTitle' => 'Añadir participante',
			'participantModal.editTitle' => 'Editar participante',
			'participantModal.desc' => 'El privilegio define qué partes se le pueden asignar.',
			'participantModal.fullName' => 'Nombre completo',
			'participantModal.nameHint' => 'Ej. Martín Salas',
			'participantModal.congregation' => 'Congregación',
			'participantModal.isLabel' => 'Es',
			'participantModal.male' => 'Hombre',
			'participantModal.female' => 'Mujer',
			'participantModal.privilege' => 'Privilegio',
			'participantModal.available' => 'Disponible',
			'participantModal.availableDesc' => 'Puede recibir asignaciones ahora mismo',
			'participantModal.deleteTitle' => '¿Eliminar definitivamente?',
			'participantModal.deleteConfirm' => ({required Object name}) => 'Se eliminará a ${name} del directorio. Esta acción no se puede deshacer. Las asignaciones ya escritas en programas no se ven afectadas.',
			'participantModal.roleDescPublisher' => 'Participa en "Seamos mejores maestros" (todos)',
			'participantModal.roleDescServant' => 'Publicador + lectura, oración y algunas partes asignables',
			'participantModal.roleDescElder' => 'Puede recibir cualquier asignación del programa',
			'participantCard.incomplete' => 'Incompleto',
			'participantCard.genderUnspecified' => 'Sin definir',
			'gender.male' => 'Hombre',
			'gender.female' => 'Mujer',
			'gender.unspecified' => 'No especificado',
			'roles.elder' => 'Anciano',
			'roles.ministerialServant' => 'Siervo ministerial',
			'roles.publisher' => 'Publicador',
			'roles.elderPlural' => 'Ancianos',
			'roles.ministerialServantPlural' => 'Siervos ministeriales',
			'roles.publisherPlural' => 'Publicadores',
			'status.draft' => 'Borrador',
			'status.complete' => 'Completo',
			'status.exported' => 'Exportado',
			'status.draftPlural' => 'Borradores',
			'status.completePlural' => 'Completos',
			'status.exportedPlural' => 'Exportados',
			'settings.title' => 'Configuración',
			'settings.subtitle' => 'Aplicación y congregaciones',
			'settings.tabApp' => 'Aplicación',
			'settings.tabCongregation' => 'Congregación',
			'settings.appearance' => 'Apariencia',
			'settings.appearanceDesc' => 'Cómo se ve la aplicación en este dispositivo.',
			'settings.theme' => 'Tema',
			'settings.themeDesc' => 'Claro, oscuro o según el sistema',
			'settings.themeLight' => 'Claro',
			'settings.themeDark' => 'Oscuro',
			'settings.themeSystem' => 'Sistema',
			'settings.general' => 'General',
			'settings.generalDesc' => 'Idioma y formato.',
			'settings.appLanguage' => 'Idioma de la app',
			'settings.timeFormat' => 'Formato de hora',
			'settings.weekStart' => 'Inicio de semana',
			'settings.pdfName' => 'Nombre en los PDF',
			'settings.notificationsTitle' => 'Notificaciones',
			'settings.notificationsDesc' => 'Recordatorios que genera la app.',
			'settings.notif.unassignedTitle' => 'Partes sin asignar',
			'settings.notif.unassignedDesc' => 'Avisar cuando falten asignaciones a 3 días de la reunión',
			'settings.notif.loadTitle' => 'Carga de asignaciones',
			'settings.notif.loadDesc' => 'Avisar si un participante acumula muchas asignaciones',
			'settings.notif.newNotebooksTitle' => 'Nuevos cuadernos',
			'settings.notif.newNotebooksDesc' => 'Avisar cuando haya un nuevo cuaderno disponible',
			'settings.notif.exportsTitle' => 'Exportaciones pendientes',
			'settings.notif.exportsDesc' => 'Recordar exportar el programa antes del fin de semana',
			'settings.data' => 'Datos',
			'settings.dataDesc' => 'Copia de seguridad de tus proyectos, participantes y congregaciones. Útil también para mover datos entre el modo local y la nube.',
			'settings.exportData' => 'Exportar datos',
			'settings.exportDataDesc' => 'Genera un archivo .jwbackup con todo',
			'settings.export' => 'Exportar',
			'settings.importData' => 'Importar datos',
			'settings.importDataDesc' => 'Restaura desde un archivo .jwbackup',
			'settings.import' => 'Importar',
			'settings.lastBackup' => 'Última copia',
			'settings.noBackupsYet' => 'Sin copias todavía',
			'settings.session' => 'Sesión',
			'settings.sessionDesc' => 'Estás usando la app en modo local en este dispositivo.',
			'settings.localMode' => 'Modo local',
			'settings.localModeDesc' => 'Los datos viven solo en este dispositivo',
			'options.timeFormat24' => '24 horas (18:00)',
			'options.timeFormat12' => '12 horas (6:00 p. m.)',
			'options.pdfNameFull' => 'Nombre y apellido',
			'options.pdfNameLastFirst' => 'Apellido, nombre',
			'options.pdfNameFirstOnly' => 'Solo nombre',
			'options.meetingLangSpanish' => 'Español',
			'options.meetingLangSign' => 'Lengua de señas',
			'options.meetingLangEnglish' => 'English',
			'options.accessAdmin' => 'Administrador',
			'options.accessEditor' => 'Editor',
			'options.accessReader' => 'Lector',
			'days.monday' => 'Lunes',
			'days.tuesday' => 'Martes',
			'days.wednesday' => 'Miércoles',
			'days.thursday' => 'Jueves',
			'days.friday' => 'Viernes',
			'days.saturday' => 'Sábado',
			'days.sunday' => 'Domingo',
			'congregation.dataTitle' => 'Datos de la congregación',
			'congregation.dataDesc' => 'Se usan en el encabezado de los programas.',
			'congregation.name' => 'Nombre',
			'congregation.number' => 'Número',
			'congregation.meetingLanguage' => 'Idioma de la reunión',
			'congregation.scheduleTitle' => 'Horarios de reunión',
			'congregation.scheduleDesc' => 'Las horas de cada parte se calculan a partir de aquí.',
			'congregation.weekdayDay' => 'Entre semana · día',
			'congregation.weekdayTime' => 'Entre semana · hora',
			'congregation.weekendDay' => 'Fin de semana · día',
			'congregation.weekendTime' => 'Fin de semana · hora',
			'congregation.auxRoom' => 'Sala auxiliar',
			'congregation.auxRoomDesc' => 'Activa una segunda sala para estudiantes por defecto',
			'congregation.usersTitle' => 'Usuarios con acceso',
			'congregation.usersDesc' => 'Quién puede ver o editar los proyectos de esta congregación.',
			'congregation.noUsers' => 'Aún no hay usuarios invitados.',
			'congregation.inviteUser' => 'Invitar usuario',
			'congregation.empty' => 'Aún no hay congregaciones.\nCrea la primera con "Nueva congregación".',
			'congregation.newCongregation' => 'Nueva congregación',
			'newCongregation.title' => 'Nueva congregación',
			'newCongregation.desc' => 'Serás su administrador. Después podrás invitar usuarios.',
			'newCongregation.create' => 'Crear congregación',
			'newCongregation.name' => 'Nombre',
			'newCongregation.nameHint' => 'Ej. Jardines del Norte',
			'newCongregation.number' => 'Número',
			'newCongregation.numberHint' => 'Ej. 152423',
			'invite.title' => 'Invitar usuario',
			'invite.desc' => 'Le llegará una invitación por correo para acceder a esta congregación.',
			'invite.send' => 'Enviar invitación',
			'invite.email' => 'Correo electrónico',
			'invite.emailHint' => 'nombre@correo.com',
			'invite.role' => 'Rol',
			'picker.assign' => 'Asignar',
			'picker.recent' => 'Recientes',
			'picker.all' => 'Todos',
			'picker.noResults' => ({required Object query}) => 'Sin resultados para “${query}”.',
			'picker.addNamed' => ({required Object query}) => 'Añadir “${query}”',
			'picker.addParticipant' => 'Añadir participante',
			'picker.closeSelector' => 'Cerrar selector',
			'preview.previewTab' => 'Vista previa',
			'preview.assignTab' => 'Asignar',
			'preview.emptyHint' => 'La vista previa aparecerá aquí.',
			'preview.error' => ({required Object error}) => 'Error al generar la vista previa:\n${error}',
			'preview.zoomIn' => 'Acercar',
			'preview.zoomOut' => 'Alejar',
			'preview.fitPage' => 'Ver hoja completa',
			'preview.fitWidth' => 'Ajustar al ancho',
			'export.export' => 'Exportar',
			'export.exportPdf' => 'Exportar PDF',
			'export.success' => ({required Object path}) => 'PDF exportado: ${path}',
			'export.error' => ({required Object error}) => 'Error al exportar: ${error}',
			'export.currentWeek' => 'Semana actual',
			'export.currentWeekSub' => 'Una hoja PDF',
			'export.fullProject' => 'Proyecto completo',
			'export.fullProjectSub' => 'Todas las semanas en un PDF',
			'export.sheets' => 'Hojas de participación',
			'export.sheetsSub' => 'Una por participante asignado',
			'projectBar.weeks' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '${n} semana', other: '${n} semanas', ), 
			'projectBar.weekN' => ({required Object n}) => 'Semana ${n}',
			'projectBar.goToWeek' => 'Ir a la semana',
			'projectBar.weekShort' => ({required Object n}) => 'Sem ${n}',
			'projectBar.auxRoom' => 'Sala auxiliar',
			'projectBar.auxRoomDesc' => 'Segunda sala para estudiantes',
			'workspace.sectionOpening' => 'Apertura',
			'workspace.sectionTreasures' => 'Tesoros de la Biblia',
			'workspace.sectionMinistry' => 'Seamos mejores maestros',
			'workspace.sectionChristianLife' => 'Nuestra vida cristiana',
			'workspace.chairmanTitle' => 'Presidente de la reunión',
			'workspace.chairman' => 'Presidente',
			'workspace.allMeeting' => 'Toda la reunión',
			'workspace.auxRoom' => 'Sala auxiliar',
			'workspace.emptyTitle' => 'El cuaderno se descarga solo.',
			'workspace.emptyMessage' => 'Normalmente está listo automáticamente. Si aún no aparece, búscalo manualmente.',
			'workspace.searchNotebook' => ({required Object issue}) => 'Buscar cuaderno ${issue}',
			'workspace.assignee' => 'Asignar…',
			'workspace.duration' => ({required Object n}) => '${n} min',
			'workspace.songTag' => 'Cántico',
			'workspace.chairmanTag' => 'A cargo del presidente',
			'workspace.slotConductor' => 'Conductor',
			'workspace.slotReader' => 'Lector',
			'workspace.slotStudent' => 'Estudiante',
			'workspace.slotAssistant' => 'Ayudante',
			'workspace.slotInCharge' => 'Encargado',
			'workspace.slotAux' => ({required Object label}) => '${label} · Aux.',
			'relativeTime.now' => 'ahora mismo',
			_ => null,
		};
	}
}
