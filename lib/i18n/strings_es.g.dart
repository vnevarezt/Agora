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
	late final Translations$portada$es portada = Translations$portada$es.internal(_root);
	late final Translations$auth$es auth = Translations$auth$es.internal(_root);
	late final Translations$security$es security = Translations$security$es.internal(_root);
	late final Translations$cloudSync$es cloudSync = Translations$cloudSync$es.internal(_root);
	late final Translations$account$es account = Translations$account$es.internal(_root);
	late final Translations$nav$es nav = Translations$nav$es.internal(_root);
	late final Translations$userMenu$es userMenu = Translations$userMenu$es.internal(_root);
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
	late final Translations$months$es months = Translations$months$es.internal(_root);
	late final Translations$congregation$es congregation = Translations$congregation$es.internal(_root);
	late final Translations$newCongregation$es newCongregation = Translations$newCongregation$es.internal(_root);
	late final Translations$invite$es invite = Translations$invite$es.internal(_root);
	late final Translations$picker$es picker = Translations$picker$es.internal(_root);
	late final Translations$preview$es preview = Translations$preview$es.internal(_root);
	late final Translations$export$es export = Translations$export$es.internal(_root);
	late final Translations$projectBar$es projectBar = Translations$projectBar$es.internal(_root);
	late final Translations$workspace$es workspace = Translations$workspace$es.internal(_root);
	late final Translations$relativeTime$es relativeTime = Translations$relativeTime$es.internal(_root);
	late final Translations$landing$es landing = Translations$landing$es.internal(_root);
	late final Translations$program$es program = Translations$program$es.internal(_root);
}

// Path: app
class Translations$app$es {
	Translations$app$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Agora'
	String get brand => 'Agora';

	/// es: 'Programa'
	String get defaultProjectName => 'Programa';
}

// Path: portada
class Translations$portada$es {
	Translations$portada$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Programas, asignaciones y hermanos de tu congregación, organizados con claridad.'
	String get tagline => 'Programas, asignaciones y hermanos de tu congregación, organizados con claridad.';

	/// es: 'Crear cuenta'
	String get createAccount => 'Crear cuenta';

	/// es: 'Iniciar sesión'
	String get signIn => 'Iniciar sesión';

	/// es: 'Continuar sin cuenta'
	String get noAccountTitle => 'Continuar sin cuenta';

	/// es: 'Solo en este dispositivo'
	String get noAccountCaption => 'Solo en este dispositivo';

	/// es: 'Herramienta independiente. No está afiliada a la Watch Tower Bible and Tract Society of Pennsylvania ni a sus entidades asociadas.'
	String get legal => 'Herramienta independiente. No está afiliada a la Watch Tower Bible and Tract Society of Pennsylvania ni a sus entidades asociadas.';

	/// es: 'La nube no está configurada en esta instalación; puedes usar el modo local.'
	String get cloudUnavailable => 'La nube no está configurada en esta instalación; puedes usar el modo local.';

	/// es: 'El modo nube no está disponible en este Mac (requiere firma de desarrollador de Apple); puedes usar el modo local.'
	String get cloudUnsupported => 'El modo nube no está disponible en este Mac (requiere firma de desarrollador de Apple); puedes usar el modo local.';
}

// Path: auth
class Translations$auth$es {
	Translations$auth$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Elegir otro modo'
	String get chooseOther => 'Elegir otro modo';

	late final Translations$auth$local$es local = Translations$auth$local$es.internal(_root);
	late final Translations$auth$cloudLock$es cloudLock = Translations$auth$cloudLock$es.internal(_root);
	late final Translations$auth$cloudVerify$es cloudVerify = Translations$auth$cloudVerify$es.internal(_root);
	late final Translations$auth$cloud$es cloud = Translations$auth$cloud$es.internal(_root);
	late final Translations$auth$reset$es reset = Translations$auth$reset$es.internal(_root);
	late final Translations$auth$keyError$es keyError = Translations$auth$keyError$es.internal(_root);
}

// Path: security
class Translations$security$es {
	Translations$security$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Seguridad'
	String get title => 'Seguridad';

	/// es: 'Cuenta local que protege tus datos cifrados en este dispositivo.'
	String get desc => 'Cuenta local que protege tus datos cifrados en este dispositivo.';

	/// es: 'Cambiar contraseña'
	String get changePassword => 'Cambiar contraseña';

	/// es: 'Vuelve a proteger la llave de cifrado con una contraseña nueva.'
	String get changePasswordDesc => 'Vuelve a proteger la llave de cifrado con una contraseña nueva.';

	/// es: 'Cambiar'
	String get change => 'Cambiar';

	/// es: 'Contraseña actual'
	String get current => 'Contraseña actual';

	/// es: 'Contraseña nueva'
	String get newPassword => 'Contraseña nueva';

	/// es: 'Confirmar contraseña nueva'
	String get confirmNew => 'Confirmar contraseña nueva';

	/// es: 'La contraseña actual no es correcta.'
	String get wrongCurrent => 'La contraseña actual no es correcta.';

	/// es: 'Contraseña actualizada.'
	String get changed => 'Contraseña actualizada.';

	/// es: 'Bloquear ahora'
	String get lockNow => 'Bloquear ahora';

	/// es: 'Cierra la sesión local; pedirá la contraseña al volver.'
	String get lockNowDesc => 'Cierra la sesión local; pedirá la contraseña al volver.';

	/// es: 'Bloquea la app; pedirá el desbloqueo del dispositivo al volver.'
	String get lockNowDescCloud => 'Bloquea la app; pedirá el desbloqueo del dispositivo al volver.';

	/// es: 'Bloquear'
	String get lock => 'Bloquear';

	/// es: 'Protege el acceso a la app en este dispositivo.'
	String get descCloud => 'Protege el acceso a la app en este dispositivo.';

	/// es: 'Desbloqueo con el dispositivo'
	String get deviceUnlock => 'Desbloqueo con el dispositivo';

	/// es: 'Entra con Touch ID, Face ID, huella o el código del equipo en lugar de tu contraseña.'
	String get deviceUnlockDesc => 'Entra con Touch ID, Face ID, huella o el código del equipo en lugar de tu contraseña.';

	/// es: 'Pide Touch ID, Face ID, huella o el código del equipo cada vez que abras la app.'
	String get deviceUnlockDescCloud => 'Pide Touch ID, Face ID, huella o el código del equipo cada vez que abras la app.';

	/// es: 'Confirma tu identidad para activar el desbloqueo con el dispositivo.'
	String get deviceUnlockPrompt => 'Confirma tu identidad para activar el desbloqueo con el dispositivo.';

	/// es: 'Desbloquea tus datos de Agora.'
	String get unlockPrompt => 'Desbloquea tus datos de Agora.';

	/// es: 'El desbloqueo del dispositivo se desactivó; entra con tu contraseña y actívalo de nuevo.'
	String get deviceUnlockKeyMissing => 'El desbloqueo del dispositivo se desactivó; entra con tu contraseña y actívalo de nuevo.';
}

// Path: cloudSync
class Translations$cloudSync$es {
	Translations$cloudSync$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Sincronización en la nube'
	String get title => 'Sincronización en la nube';

	/// es: 'Tus datos se guardan cifrados y se restauran solos al iniciar sesión en cualquiera de tus dispositivos.'
	String get desc => 'Tus datos se guardan cifrados y se restauran solos al iniciar sesión en cualquiera de tus dispositivos.';

	/// es: 'Inicia sesión en la nube para activar la sincronización.'
	String get signedOut => 'Inicia sesión en la nube para activar la sincronización.';

	/// es: 'No se pudo completar. Inténtalo de nuevo.'
	String get unknownError => 'No se pudo completar. Inténtalo de nuevo.';

	/// es: 'Sincronización activa'
	String get ready => 'Sincronización activa';

	/// es: 'Sincronizando…'
	String get statusSyncing => 'Sincronizando…';

	/// es: 'Sin conexión'
	String get statusOffline => 'Sin conexión';

	/// es: 'Error de sincronización'
	String get statusError => 'Error de sincronización';

	/// es: 'Última sincronización: {when}'
	String lastSync({required Object when}) => 'Última sincronización: ${when}';

	/// es: 'Se sincronizará automáticamente'
	String get neverSynced => 'Se sincronizará automáticamente';

	/// es: 'Ya no tienes acceso a una congregación; tus datos locales se conservan.'
	String get errorPermission => 'Ya no tienes acceso a una congregación; tus datos locales se conservan.';

	/// es: 'Sin conexión; se reintentará automáticamente.'
	String get errorOffline => 'Sin conexión; se reintentará automáticamente.';

	/// es: 'Ocurrió un error al sincronizar.'
	String get errorUnknown => 'Ocurrió un error al sincronizar.';

	/// es: 'Recuperando tus datos…'
	String get restoring => 'Recuperando tus datos…';

	/// es: '{done} de {total} congregaciones'
	String restoringProgress({required Object done, required Object total}) => '${done} de ${total} congregaciones';

	/// es: 'Sin conexión. Tus datos se recuperarán al reconectar.'
	String get restoreOffline => 'Sin conexión. Tus datos se recuperarán al reconectar.';
}

// Path: account
class Translations$account$es {
	Translations$account$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Cuenta en la nube'
	String get title => 'Cuenta en la nube';

	/// es: 'Identidad opcional para sincronizar en el futuro. No sustituye a la contraseña local.'
	String get desc => 'Identidad opcional para sincronizar en el futuro. No sustituye a la contraseña local.';

	/// es: 'Nube no configurada'
	String get notConfigured => 'Nube no configurada';

	/// es: 'Esta instalación no tiene proyecto de Firebase: la app funciona 100 % local.'
	String get notConfiguredDesc => 'Esta instalación no tiene proyecto de Firebase: la app funciona 100 % local.';

	/// es: 'Iniciar sesión'
	String get signIn => 'Iniciar sesión';

	/// es: 'Crear cuenta'
	String get register => 'Crear cuenta';

	/// es: 'Continuar con Google'
	String get google => 'Continuar con Google';

	/// es: 'o'
	String get or => 'o';

	/// es: 'Correo electrónico'
	String get email => 'Correo electrónico';

	/// es: 'Contraseña'
	String get password => 'Contraseña';

	/// es: 'Sesión iniciada'
	String get signedInAs => 'Sesión iniciada';

	/// es: 'Cerrar sesión'
	String get signOut => 'Cerrar sesión';

	/// es: 'Cerrar la sesión de nube no bloquea tus datos locales; para eso usa Seguridad → Bloquear ahora.'
	String get localGateNote => 'Cerrar la sesión de nube no bloquea tus datos locales; para eso usa Seguridad → Bloquear ahora.';

	/// es: 'Zona de peligro'
	String get dangerZone => 'Zona de peligro';

	/// es: 'Borrar mi cuenta'
	String get deleteAccount => 'Borrar mi cuenta';

	/// es: 'Elimina tu cuenta de la nube y todos los datos de este dispositivo.'
	String get deleteAccountDesc => 'Elimina tu cuenta de la nube y todos los datos de este dispositivo.';

	/// es: 'Borrar mi cuenta'
	String get deleteTitle => 'Borrar mi cuenta';

	/// es: 'Se borrará tu cuenta de la nube y TODOS los datos de este dispositivo. Esta acción no se puede deshacer. Las congregaciones donde eres el único integrante se eliminarán de la nube; de las demás simplemente saldrás.'
	String get deleteWarning => 'Se borrará tu cuenta de la nube y TODOS los datos de este dispositivo. Esta acción no se puede deshacer. Las congregaciones donde eres el único integrante se eliminarán de la nube; de las demás simplemente saldrás.';

	/// es: 'No puedes borrar tu cuenta todavía: eres el único administrador de {congregations}. Pasa el rol de administrador a otra persona o quita a los demás miembros primero.'
	String deleteBlocked({required Object congregations}) => 'No puedes borrar tu cuenta todavía: eres el único administrador de ${congregations}. Pasa el rol de administrador a otra persona o quita a los demás miembros primero.';

	/// es: 'Confirma tu contraseña para continuar.'
	String get deleteReauthEmail => 'Confirma tu contraseña para continuar.';

	/// es: 'Se te pedirá volver a iniciar sesión con Google para confirmar.'
	String get deleteReauthGoogle => 'Se te pedirá volver a iniciar sesión con Google para confirmar.';

	/// es: 'Borrar mi cuenta'
	String get deleteConfirm => 'Borrar mi cuenta';

	/// es: 'No se pudo borrar la cuenta. Inténtalo de nuevo.'
	String get deleteError => 'No se pudo borrar la cuenta. Inténtalo de nuevo.';

	late final Translations$account$errors$es errors = Translations$account$errors$es.internal(_root);
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

// Path: userMenu
class Translations$userMenu$es {
	Translations$userMenu$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Perfil local'
	String get localProfile => 'Perfil local';

	/// es: 'Cuenta en la nube'
	String get cloudAccount => 'Cuenta en la nube';
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

	/// es: 'asignados'
	String get assigned => 'asignados';
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

	/// es: 'Tienes'
	String get youHave => 'Tienes';

	/// es: '1 proyecto en curso'
	String get draftsOne => '1 proyecto en curso';

	/// es: '{n} proyectos en curso'
	String draftsMany({required Object n}) => '${n} proyectos en curso';

	/// es: 'Nuevo proyecto'
	String get newProject => 'Nuevo proyecto';

	/// es: 'Todo estado'
	String get allStatus => 'Todo estado';

	/// es: 'Tus proyectos'
	String get projects => 'Tus proyectos';

	/// es: 'Recordatorios'
	String get reminders => 'Recordatorios';

	/// es: 'Ver todo'
	String get seeAll => 'Ver todo';

	/// es: 'Continúa donde quedaste'
	String get continueWhere => 'Continúa donde quedaste';

	/// es: 'Continuar'
	String get continueCta => 'Continuar';

	/// es: '{done} de {total} asignaciones completas'
	String assignmentsDone({required Object done, required Object total}) => '${done} de ${total} asignaciones completas';

	/// es: 'Pendientes'
	String get pending => 'Pendientes';

	/// es: '{n} asignaciones pendientes'
	String pendingItem({required Object n}) => '${n} asignaciones pendientes';

	/// es: 'Abrir proyecto'
	String get openProject => 'Abrir proyecto';

	/// es: 'Resolver pendientes'
	String get resolvePending => 'Resolver pendientes';

	/// es: 'Todo al día ✨'
	String get allDone => 'Todo al día ✨';
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

	/// es: 'Nombre para el programa'
	String get fullName => 'Nombre para el programa';

	/// es: 'Ej. Martín Salas'
	String get nameHint => 'Ej. Martín Salas';

	/// es: 'Nombre'
	String get firstName => 'Nombre';

	/// es: 'Apellidos'
	String get lastName => 'Apellidos';

	/// es: 'Congregación de origen'
	String get congregation => 'Congregación de origen';

	/// es: 'Solo para visitantes; vacío = tu congregación'
	String get originHint => 'Solo para visitantes; vacío = tu congregación';

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

	/// es: 'Copia de seguridad cifrada de tus congregaciones, participantes y programas. Útil también para mover datos entre dispositivos.'
	String get dataDesc => 'Copia de seguridad cifrada de tus congregaciones, participantes y programas. Útil también para mover datos entre dispositivos.';

	/// es: 'Exportar datos'
	String get exportData => 'Exportar datos';

	/// es: 'Genera un archivo .agora cifrado con contraseña'
	String get exportDataDesc => 'Genera un archivo .agora cifrado con contraseña';

	/// es: 'Exportar'
	String get export => 'Exportar';

	/// es: 'Importar datos'
	String get importData => 'Importar datos';

	/// es: 'Restaura y fusiona desde un archivo .agora'
	String get importDataDesc => 'Restaura y fusiona desde un archivo .agora';

	/// es: 'Importar'
	String get import => 'Importar';

	/// es: 'Última copia'
	String get lastBackup => 'Última copia';

	/// es: 'Sin copias todavía'
	String get noBackupsYet => 'Sin copias todavía';

	/// es: 'Contraseña de la copia'
	String get backupPasswordTitle => 'Contraseña de la copia';

	/// es: 'Protege el archivo: sin ella no se puede restaurar.'
	String get backupPasswordDesc => 'Protege el archivo: sin ella no se puede restaurar.';

	/// es: 'Repite la contraseña'
	String get backupPasswordRepeat => 'Repite la contraseña';

	/// es: 'Las contraseñas no coinciden'
	String get backupPasswordMismatch => 'Las contraseñas no coinciden';

	/// es: 'La contraseña con la que se exportó el archivo.'
	String get backupImportPasswordDesc => 'La contraseña con la que se exportó el archivo.';

	/// es: 'Copia guardada: {path}'
	String backupSaved({required Object path}) => 'Copia guardada: ${path}';

	/// es: 'Copia compartida'
	String get backupSharedMsg => 'Copia compartida';

	/// es: 'Restauración completa: {n} registros actualizados'
	String backupRestored({required Object n}) => 'Restauración completa: ${n} registros actualizados';

	/// es: 'Contraseña incorrecta'
	String get backupWrongPassword => 'Contraseña incorrecta';

	/// es: 'El archivo no es una copia de Agora válida'
	String get backupMalformed => 'El archivo no es una copia de Agora válida';

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

// Path: months
class Translations$months$es {
	Translations$months$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Enero'
	String get january => 'Enero';

	/// es: 'Febrero'
	String get february => 'Febrero';

	/// es: 'Marzo'
	String get march => 'Marzo';

	/// es: 'Abril'
	String get april => 'Abril';

	/// es: 'Mayo'
	String get may => 'Mayo';

	/// es: 'Junio'
	String get june => 'Junio';

	/// es: 'Julio'
	String get july => 'Julio';

	/// es: 'Agosto'
	String get august => 'Agosto';

	/// es: 'Septiembre'
	String get september => 'Septiembre';

	/// es: 'Octubre'
	String get october => 'Octubre';

	/// es: 'Noviembre'
	String get november => 'Noviembre';

	/// es: 'Diciembre'
	String get december => 'Diciembre';
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

	/// es: 'Mi congregación'
	String get defaultName => 'Mi congregación';

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

	/// es: 'Unirse con un código'
	String get joinWithCode => 'Unirse con un código';

	/// es: 'tú'
	String get you => 'tú';

	/// es: 'Admin'
	String get roleAdmin => 'Admin';

	/// es: 'Editor'
	String get roleEditor => 'Editor';

	/// es: 'Lectura'
	String get roleViewer => 'Lectura';

	/// es: 'Cambiar permisos'
	String get editAccess => 'Cambiar permisos';

	/// es: 'Quitar acceso'
	String get revoke => 'Quitar acceso';

	/// es: 'Quitar acceso'
	String get revokeTitle => 'Quitar acceso';

	/// es: '{name} dejará de recibir cambios. Se generará una clave nueva para el resto y las invitaciones pendientes se cancelarán. Lo que ya tenga descargado seguirá en su dispositivo.'
	String revokeConfirm({required Object name}) => '${name} dejará de recibir cambios. Se generará una clave nueva para el resto y las invitaciones pendientes se cancelarán. Lo que ya tenga descargado seguirá en su dispositivo.';

	/// es: 'Debe quedar al menos una persona con permiso de administración.'
	String get lastAdmin => 'Debe quedar al menos una persona con permiso de administración.';

	/// es: 'Solo tienes acceso de lectura en esta congregación.'
	String get readOnly => 'Solo tienes acceso de lectura en esta congregación.';

	/// es: 'No se ha podido cargar la lista de miembros.'
	String get membersError => 'No se ha podido cargar la lista de miembros.';

	/// es: 'Invitaciones pendientes'
	String get pendingLabel => 'Invitaciones pendientes';

	/// es: 'Borrar datos de la nube'
	String get deleteCloud => 'Borrar datos de la nube';

	/// es: 'Borrar los datos de la nube'
	String get deleteCloudTitle => 'Borrar los datos de la nube';

	/// es: 'Se eliminará el espacio en la nube de esta congregación y TODOS los demás miembros perderán el acceso. Tus datos locales se conservan. Esta acción no se puede deshacer.'
	String get deleteCloudConfirm => 'Se eliminará el espacio en la nube de esta congregación y TODOS los demás miembros perderán el acceso. Tus datos locales se conservan. Esta acción no se puede deshacer.';

	/// es: 'Borrar de la nube'
	String get deleteCloudButton => 'Borrar de la nube';

	/// es: 'No se pudieron borrar los datos de la nube.'
	String get deleteCloudError => 'No se pudieron borrar los datos de la nube.';
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

	/// es: 'Invitar a la congregación'
	String get title => 'Invitar a la congregación';

	/// es: 'Genera un código y compártelo por un canal privado. Sirve una sola vez.'
	String get desc => 'Genera un código y compártelo por un canal privado. Sirve una sola vez.';

	/// es: 'Crear código'
	String get create => 'Crear código';

	/// es: 'Permisos'
	String get capabilities => 'Permisos';

	/// es: 'Lo que podrá hacer quien use el código.'
	String get capabilitiesDesc => 'Lo que podrá hacer quien use el código.';

	/// es: 'Administrar'
	String get capAdmin => 'Administrar';

	/// es: 'Miembros, invitaciones y datos de la congregación.'
	String get capAdminDesc => 'Miembros, invitaciones y datos de la congregación.';

	/// es: 'Participantes'
	String get capPeople => 'Participantes';

	/// es: 'Editar el directorio de personas.'
	String get capPeopleDesc => 'Editar el directorio de personas.';

	/// es: 'Programas'
	String get capPrograms => 'Programas';

	/// es: 'Crear y editar proyectos y asignaciones.'
	String get capProgramsDesc => 'Crear y editar proyectos y asignaciones.';

	/// es: 'Código de invitación'
	String get codeTitle => 'Código de invitación';

	/// es: 'Válido durante 7 días y de un solo uso. Quien lo tenga podrá leer los datos de la congregación: compártelo solo por un canal privado.'
	String get codeDesc => 'Válido durante 7 días y de un solo uso. Quien lo tenga podrá leer los datos de la congregación: compártelo solo por un canal privado.';

	/// es: 'Copiar'
	String get copy => 'Copiar';

	/// es: 'Código copiado'
	String get copied => 'Código copiado';

	/// es: 'Compartir'
	String get share => 'Compartir';

	/// es: 'Hecho'
	String get done => 'Hecho';

	/// es: 'Invitaciones pendientes'
	String get pending => 'Invitaciones pendientes';

	/// es: 'Caduca el {date}'
	String expiresOn({required Object date}) => 'Caduca el ${date}';

	/// es: 'Caducada'
	String get expired => 'Caducada';

	/// es: 'Cancelar invitación'
	String get cancel => 'Cancelar invitación';

	/// es: 'Unirse con un código'
	String get joinTitle => 'Unirse con un código';

	/// es: 'Pega el código que te han compartido.'
	String get joinDesc => 'Pega el código que te han compartido.';

	/// es: 'Código'
	String get codeLabel => 'Código';

	/// es: 'agora-inv:1:…'
	String get codeHint => 'agora-inv:1:…';

	/// es: 'Unirse'
	String get join => 'Unirse';

	/// es: 'Te has unido a la congregación.'
	String get joined => 'Te has unido a la congregación.';

	/// es: 'Ese código no es válido. Cópialo entero, sin cortarlo.'
	String get errorInvalid => 'Ese código no es válido. Cópialo entero, sin cortarlo.';

	/// es: 'Esta invitación ya no existe: puede que alguien la haya usado.'
	String get errorMissing => 'Esta invitación ya no existe: puede que alguien la haya usado.';

	/// es: 'Esta invitación ha caducado. Pide una nueva.'
	String get errorExpired => 'Esta invitación ha caducado. Pide una nueva.';

	/// es: 'Ya perteneces a esta congregación.'
	String get errorAlreadyMember => 'Ya perteneces a esta congregación.';

	/// es: 'Las claves de sincronización no están disponibles en este dispositivo.'
	String get errorKeys => 'Las claves de sincronización no están disponibles en este dispositivo.';

	/// es: 'No se ha podido completar. Inténtalo de nuevo.'
	String get errorUnknown => 'No se ha podido completar. Inténtalo de nuevo.';

	/// es: 'Pegar'
	String get paste => 'Pegar';
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

	/// es: 'Exportar'
	String get exportPdf => 'Exportar';

	/// es: 'Guardado en: {path}'
	String success({required Object path}) => 'Guardado en: ${path}';

	/// es: 'Archivo compartido'
	String get shared => 'Archivo compartido';

	/// es: 'Error al exportar: {error}'
	String error({required Object error}) => 'Error al exportar: ${error}';

	/// es: 'PDF'
	String get formatPdf => 'PDF';

	/// es: 'Imagen'
	String get formatImage => 'Imagen';

	/// es: 'Guardar'
	String get saveAction => 'Guardar';

	/// es: 'Compartir'
	String get shareAction => 'Compartir';

	/// es: 'Semana actual'
	String get currentWeek => 'Semana actual';

	/// es: 'Una semana'
	String get currentWeekSub => 'Una semana';

	/// es: 'Hoja actual'
	String get currentSheet => 'Hoja actual';

	/// es: 'Dos semanas en una hoja'
	String get currentSheetSub => 'Dos semanas en una hoja';

	/// es: 'Descarga un cuaderno y elige una semana primero.'
	String get noWeeks => 'Descarga un cuaderno y elige una semana primero.';
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

	/// es: 'Semana anterior'
	String get prevWeek => 'Semana anterior';

	/// es: 'Semana siguiente'
	String get nextWeek => 'Semana siguiente';

	/// es: 'Sem {n}'
	String weekShort({required Object n}) => 'Sem ${n}';

	/// es: 'Sala auxiliar'
	String get auxRoom => 'Sala auxiliar';

	/// es: 'Segunda sala para estudiantes'
	String get auxRoomDesc => 'Segunda sala para estudiantes';

	/// es: 'Dos por hoja'
	String get twoPerSheet => 'Dos por hoja';

	/// es: 'Dos semanas en la misma hoja'
	String get twoPerSheetDesc => 'Dos semanas en la misma hoja';

	/// es: 'Visita del superintendente'
	String get circuitOverseer => 'Visita del superintendente';

	/// es: 'Reemplaza el estudio bíblico por un discurso'
	String get circuitOverseerDesc => 'Reemplaza el estudio bíblico por un discurso';
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

	/// es: 'Orador'
	String get slotSpeaker => 'Orador';

	/// es: '{label} · Aux.'
	String slotAux({required Object label}) => '${label} · Aux.';

	/// es: 'Editar título'
	String get editTitle => 'Editar título';

	/// es: 'Título de la asignación'
	String get editTitleHint => 'Título de la asignación';

	/// es: 'Restablecer'
	String get restoreTitle => 'Restablecer';
}

// Path: relativeTime
class Translations$relativeTime$es {
	Translations$relativeTime$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'ahora mismo'
	String get now => 'ahora mismo';

	/// es: 'hace {n} min'
	String minutes({required Object n}) => 'hace ${n} min';

	/// es: 'hace {n} h'
	String hours({required Object n}) => 'hace ${n} h';

	/// es: 'hace {n} d'
	String days({required Object n}) => 'hace ${n} d';
}

// Path: landing
class Translations$landing$es {
	Translations$landing$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$landing$nav$es nav = Translations$landing$nav$es.internal(_root);

	/// es: 'Iniciar sesión'
	String get signIn => 'Iniciar sesión';

	/// es: 'Abrir Agora'
	String get openApp => 'Abrir Agora';

	/// es: 'En pruebas'
	String get betaBadge => 'En pruebas';

	/// es: 'Volver arriba'
	String get backToTop => 'Volver arriba';

	late final Translations$landing$hero$es hero = Translations$landing$hero$es.internal(_root);
	late final Translations$landing$howItWorks$es howItWorks = Translations$landing$howItWorks$es.internal(_root);
	late final Translations$landing$schedules$es schedules = Translations$landing$schedules$es.internal(_root);
	late final Translations$landing$preview$es preview = Translations$landing$preview$es.internal(_root);
	late final Translations$landing$features$es features = Translations$landing$features$es.internal(_root);
	late final Translations$landing$privacy$es privacy = Translations$landing$privacy$es.internal(_root);
	late final Translations$landing$downloads$es downloads = Translations$landing$downloads$es.internal(_root);
	late final Translations$landing$footer$es footer = Translations$landing$footer$es.internal(_root);
}

// Path: program
class Translations$program$es {
	Translations$program$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Canción {n}'
	String song({required Object n}) => 'Canción ${n}';

	/// es: 'Palabras de introducción'
	String get openingWords => 'Palabras de introducción';

	/// es: 'Palabras de conclusión'
	String get closingWords => 'Palabras de conclusión';

	/// es: 'Discurso del superintendente de circuito'
	String get circuitOverseerTalk => 'Discurso del superintendente de circuito';

	/// es: '{title} ({n} mins.)'
	String partWithDuration({required Object title, required Object n}) => '${title} (${n} mins.)';

	/// es: '{title} ({n} min.)'
	String commentsWithDuration({required Object title, required Object n}) => '${title} (${n} min.)';

	/// es: 'Estudiante:'
	String get roleStudent => 'Estudiante:';

	/// es: 'Estudiante/Ayudante:'
	String get roleStudentAssistant => 'Estudiante/Ayudante:';

	/// es: 'Conductor/Lector:'
	String get roleConductorReader => 'Conductor/Lector:';

	/// es: 'Oración:'
	String get rolePrayer => 'Oración:';

	/// es: 'Orador:'
	String get roleSpeaker => 'Orador:';

	/// es: 'Programa para la reunión de entre semana'
	String get title => 'Programa para la reunión de entre semana';

	/// es: 'Presidente: '
	String get chairman => 'Presidente: ';

	/// es: 'Auditorio principal'
	String get mainHall => 'Auditorio principal';

	/// es: 'Sala Auxiliar'
	String get auxRoom => 'Sala Auxiliar';

	/// es: 'TESOROS DE LA BIBLIA'
	String get sectionTreasures => 'TESOROS DE LA BIBLIA';

	/// es: 'SEAMOS MEJORES MAESTROS'
	String get sectionMinistry => 'SEAMOS MEJORES MAESTROS';

	/// es: 'NUESTRA VIDA CRISTIANA'
	String get sectionChristianLife => 'NUESTRA VIDA CRISTIANA';
}

// Path: auth.local
class Translations$auth$local$es {
	Translations$auth$local$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Modo local'
	String get pill => 'Modo local';

	/// es: 'Crea tu perfil local'
	String get createTitle => 'Crea tu perfil local';

	/// es: 'Se guarda únicamente en este dispositivo.'
	String get createSub => 'Se guarda únicamente en este dispositivo.';

	/// es: 'Protege tus datos'
	String get migrateTitle => 'Protege tus datos';

	/// es: 'Esta versión añade un perfil local: crea una contraseña para proteger los datos que ya tienes en este dispositivo.'
	String get migrateSub => 'Esta versión añade un perfil local: crea una contraseña para proteger los datos que ya tienes en este dispositivo.';

	/// es: 'Tu nombre'
	String get name => 'Tu nombre';

	/// es: 'Ej. Andrés Beltrán'
	String get nameHint => 'Ej. Andrés Beltrán';

	/// es: 'Contraseña'
	String get password => 'Contraseña';

	/// es: 'Mínimo 8 caracteres'
	String get passwordHint => 'Mínimo 8 caracteres';

	/// es: 'Confirmar contraseña'
	String get confirm => 'Confirmar contraseña';

	/// es: 'Repite la contraseña'
	String get confirmHint => 'Repite la contraseña';

	/// es: 'Tu nombre, contraseña y todos tus datos viven solo aquí. Si olvidas la contraseña '
	String get note1 => 'Tu nombre, contraseña y todos tus datos viven solo aquí. Si olvidas la contraseña ';

	/// es: 'no podremos recuperarla'
	String get noteBold => 'no podremos recuperarla';

	/// es: ' — te recomendamos exportar copias de seguridad desde Configuración.'
	String get note2 => ' — te recomendamos exportar copias de seguridad desde Configuración.';

	/// es: 'Crear perfil y empezar'
	String get createButton => 'Crear perfil y empezar';

	/// es: 'Protegiendo…'
	String get working => 'Protegiendo…';

	/// es: 'La contraseña debe tener al menos 8 caracteres.'
	String get tooShort => 'La contraseña debe tener al menos 8 caracteres.';

	/// es: 'Las contraseñas no coinciden.'
	String get mismatch => 'Las contraseñas no coinciden.';

	/// es: 'Perfil local · este dispositivo'
	String get profileCaption => 'Perfil local · este dispositivo';

	/// es: 'Desbloquear'
	String get unlockButton => 'Desbloquear';

	/// es: 'Descifrando…'
	String get unlocking => 'Descifrando…';

	/// es: 'Contraseña incorrecta.'
	String get wrongPassword => 'Contraseña incorrecta.';

	/// es: '¿Empezar de cero?'
	String get startOver => '¿Empezar de cero?';

	/// es: 'Crear otro perfil'
	String get createAnother => 'Crear otro perfil';

	/// es: 'Usar desbloqueo del dispositivo'
	String get deviceUnlockButton => 'Usar desbloqueo del dispositivo';
}

// Path: auth.cloudLock
class Translations$auth$cloudLock$es {
	Translations$auth$cloudLock$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Sesión bloqueada'
	String get title => 'Sesión bloqueada';

	/// es: 'Confirma tu identidad para entrar.'
	String get caption => 'Confirma tu identidad para entrar.';

	/// es: 'Desbloquear'
	String get unlock => 'Desbloquear';

	/// es: '¿No eres tú?'
	String get signOutQuestion => '¿No eres tú?';

	/// es: 'Cerrar sesión'
	String get signOut => 'Cerrar sesión';
}

// Path: auth.cloudVerify
class Translations$auth$cloudVerify$es {
	Translations$auth$cloudVerify$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Verifica tu correo'
	String get title => 'Verifica tu correo';

	/// es: 'Te enviamos un enlace a {email}. Ábrelo para activar tu cuenta — esta pantalla continúa sola en cuanto lo confirmes.'
	String caption({required Object email}) => 'Te enviamos un enlace a ${email}. Ábrelo para activar tu cuenta — esta pantalla continúa sola en cuanto lo confirmes.';

	/// es: 'Ya lo verifiqué'
	String get checkNow => 'Ya lo verifiqué';

	/// es: 'Todavía no confirmamos tu correo. Revisa tu bandeja de entrada (y spam) y vuelve a intentar.'
	String get notYetVerified => 'Todavía no confirmamos tu correo. Revisa tu bandeja de entrada (y spam) y vuelve a intentar.';

	/// es: 'Reenviar correo'
	String get resend => 'Reenviar correo';

	/// es: 'Reenviar en {seconds}s'
	String resendIn({required Object seconds}) => 'Reenviar en ${seconds}s';

	/// es: '¿No es tu correo?'
	String get signOutQuestion => '¿No es tu correo?';

	/// es: 'Cerrar sesión'
	String get signOut => 'Cerrar sesión';
}

// Path: auth.cloud
class Translations$auth$cloud$es {
	Translations$auth$cloud$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Modo nube'
	String get pill => 'Modo nube';

	/// es: 'Inicia sesión'
	String get loginTitle => 'Inicia sesión';

	/// es: 'Tus congregaciones y proyectos te esperan.'
	String get loginSub => 'Tus congregaciones y proyectos te esperan.';

	/// es: 'Crea tu cuenta'
	String get registerTitle => 'Crea tu cuenta';

	/// es: 'Sincroniza y comparte con tu congregación.'
	String get registerSub => 'Sincroniza y comparte con tu congregación.';

	/// es: 'Continuar con Google'
	String get google => 'Continuar con Google';

	/// es: 'o con tu correo'
	String get orEmail => 'o con tu correo';

	/// es: 'Tu nombre'
	String get name => 'Tu nombre';

	/// es: 'Ej. Andrés Beltrán'
	String get nameHint => 'Ej. Andrés Beltrán';

	/// es: 'Correo'
	String get email => 'Correo';

	/// es: 'tu@correo.com'
	String get emailHint => 'tu@correo.com';

	/// es: 'Contraseña'
	String get password => 'Contraseña';

	/// es: 'Tu contraseña'
	String get passwordHintLogin => 'Tu contraseña';

	/// es: 'Mínimo 8 caracteres'
	String get passwordHintRegister => 'Mínimo 8 caracteres';

	/// es: 'Confirmar contraseña'
	String get confirm => 'Confirmar contraseña';

	/// es: 'Repite la contraseña'
	String get confirmHint => 'Repite la contraseña';

	/// es: '¿Olvidaste tu contraseña?'
	String get forgot => '¿Olvidaste tu contraseña?';

	/// es: 'Volver a iniciar sesión'
	String get backToLogin => 'Volver a iniciar sesión';

	/// es: 'Restablece tu contraseña'
	String get resetTitle => 'Restablece tu contraseña';

	/// es: 'Escribe tu correo y te enviaremos un enlace para crear una nueva contraseña.'
	String get resetSub => 'Escribe tu correo y te enviaremos un enlace para crear una nueva contraseña.';

	/// es: 'Enviar enlace'
	String get resetButton => 'Enviar enlace';

	/// es: 'Revisa tu correo'
	String get resetSentTitle => 'Revisa tu correo';

	/// es: 'Si existe una cuenta con {email}, te enviamos un enlace para restablecer tu contraseña.'
	String resetSentDesc({required Object email}) => 'Si existe una cuenta con ${email}, te enviamos un enlace para restablecer tu contraseña.';

	/// es: 'Reenviar enlace'
	String get resetResend => 'Reenviar enlace';

	/// es: 'Reenviar en {seconds}s'
	String resetResendIn({required Object seconds}) => 'Reenviar en ${seconds}s';

	/// es: 'Iniciar sesión'
	String get loginButton => 'Iniciar sesión';

	/// es: 'Crear cuenta'
	String get registerButton => 'Crear cuenta';

	/// es: '¿No tienes cuenta?'
	String get noAccount => '¿No tienes cuenta?';

	/// es: 'Regístrate'
	String get register => 'Regístrate';

	/// es: '¿Ya tienes cuenta?'
	String get hasAccount => '¿Ya tienes cuenta?';

	/// es: 'Inicia sesión'
	String get login => 'Inicia sesión';

	/// es: 'Nube no configurada'
	String get unavailableTitle => 'Nube no configurada';

	/// es: 'Esta instalación no tiene proyecto de Firebase; el modo nube no está disponible.'
	String get unavailableDesc => 'Esta instalación no tiene proyecto de Firebase; el modo nube no está disponible.';
}

// Path: auth.reset
class Translations$auth$reset$es {
	Translations$auth$reset$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Borrar todos los datos'
	String get title => 'Borrar todos los datos';

	/// es: 'Sin la contraseña no es posible recuperar la información: se borrarán permanentemente la base de datos local y sus llaves, y empezarás de cero.'
	String get warning => 'Sin la contraseña no es posible recuperar la información: se borrarán permanentemente la base de datos local y sus llaves, y empezarás de cero.';

	/// es: 'BORRAR'
	String get confirmPhrase => 'BORRAR';

	/// es: 'Escribe {phrase} para confirmar'
	String confirmHint({required Object phrase}) => 'Escribe ${phrase} para confirmar';

	/// es: 'Borrar todo'
	String get button => 'Borrar todo';
}

// Path: auth.keyError
class Translations$auth$keyError$es {
	Translations$auth$keyError$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'No se pudo acceder al llavero del sistema'
	String get title => 'No se pudo acceder al llavero del sistema';

	/// es: 'Reintentar'
	String get retry => 'Reintentar';
}

// Path: account.errors
class Translations$account$errors$es {
	Translations$account$errors$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'El correo no es válido.'
	String get invalidEmail => 'El correo no es válido.';

	/// es: 'No existe una cuenta con ese correo.'
	String get userNotFound => 'No existe una cuenta con ese correo.';

	/// es: 'Correo o contraseña incorrectos.'
	String get wrongPassword => 'Correo o contraseña incorrectos.';

	/// es: 'Ya existe una cuenta con ese correo.'
	String get emailInUse => 'Ya existe una cuenta con ese correo.';

	/// es: 'La contraseña es demasiado débil (mínimo 6 caracteres).'
	String get weakPassword => 'La contraseña es demasiado débil (mínimo 6 caracteres).';

	/// es: 'Sin conexión. Inténtalo de nuevo.'
	String get network => 'Sin conexión. Inténtalo de nuevo.';

	/// es: 'Por seguridad, vuelve a iniciar sesión e inténtalo de nuevo.'
	String get requiresRecentLogin => 'Por seguridad, vuelve a iniciar sesión e inténtalo de nuevo.';

	/// es: 'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.'
	String get tooManyRequests => 'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.';

	/// es: 'No se pudo completar la operación. Inténtalo de nuevo.'
	String get unknown => 'No se pudo completar la operación. Inténtalo de nuevo.';
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

// Path: landing.nav
class Translations$landing$nav$es {
	Translations$landing$nav$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Cómo funciona'
	String get howItWorks => 'Cómo funciona';

	/// es: 'Horarios'
	String get schedules => 'Horarios';

	/// es: 'Tus datos'
	String get privacy => 'Tus datos';

	/// es: 'Descargas'
	String get downloads => 'Descargas';
}

// Path: landing.hero
class Translations$landing$hero$es {
	Translations$landing$hero$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Tú pones los nombres. Ya está.'
	String get title => 'Tú pones los nombres. Ya está.';

	/// es: 'Agora calcula las horas y te deja el PDF listo para imprimir.'
	String get subtitle => 'Agora calcula las horas y te deja el PDF listo para imprimir.';

	/// es: 'Probar ahora'
	String get cta => 'Probar ahora';

	/// es: 'Sin cuenta. Sin instalar nada.'
	String get note => 'Sin cuenta. Sin instalar nada.';
}

// Path: landing.howItWorks
class Translations$landing$howItWorks$es {
	Translations$landing$howItWorks$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Son tres pasos.'
	String get title => 'Son tres pasos.';

	/// es: 'Eliges las semanas'
	String get step1Title => 'Eliges las semanas';

	/// es: 'La guía ya está descargada, con sus partes y canciones.'
	String get step1Body => 'La guía ya está descargada, con sus partes y canciones.';

	/// es: 'Pones los nombres'
	String get step2Title => 'Pones los nombres';

	/// es: 'Escribes las primeras letras y eliges.'
	String get step2Body => 'Escribes las primeras letras y eliges.';

	/// es: 'Lo imprimes'
	String get step3Title => 'Lo imprimes';

	/// es: 'Guardas el PDF o lo compartes.'
	String get step3Body => 'Guardas el PDF o lo compartes.';
}

// Path: landing.schedules
class Translations$landing$schedules$es {
	Translations$landing$schedules$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'No vuelvas a sumar minutos a mano.'
	String get title => 'No vuelvas a sumar minutos a mano.';

	/// es: 'Cambia una parte y todas las horas de abajo se mueven solas.'
	String get body => 'Cambia una parte y todas las horas de abajo se mueven solas.';

	/// es: '¿Viene el superintendente? Lo marcas y el programa se reordena.'
	String get circuit => '¿Viene el superintendente? Lo marcas y el programa se reordena.';

	/// es: 'Sobran 26 min · 8·8·10 a las canciones'
	String get slack => 'Sobran 26 min · 8·8·10 a las canciones';

	/// es: 'Semana normal · inicio 18:00'
	String get sampleLabel => 'Semana normal · inicio 18:00';

	/// es: '19:45'
	String get sampleTargetEnd => '19:45';

	/// es: 'Canción y oración'
	String get sampleOpeningSong => 'Canción y oración';

	/// es: 'Palabras de introducción'
	String get sampleIntro => 'Palabras de introducción';

	/// es: 'Tesoros de la Biblia'
	String get sampleTreasures => 'Tesoros de la Biblia';

	/// es: '25 min'
	String get sampleTreasuresDuration => '25 min';

	/// es: 'Seamos mejores maestros'
	String get sampleMinistry => 'Seamos mejores maestros';

	/// es: '15 min fijos'
	String get sampleMinistryDuration => '15 min fijos';

	/// es: 'Canción'
	String get sampleSong2 => 'Canción';

	/// es: 'Nuestra vida cristiana'
	String get sampleChristianLife => 'Nuestra vida cristiana';

	/// es: '5 min'
	String get sampleChristianLifeDuration => '5 min';

	/// es: 'Estudio bíblico de la congregación'
	String get sampleBibleStudy => 'Estudio bíblico de la congregación';

	/// es: 'Palabras de conclusión'
	String get sampleClosingWords => 'Palabras de conclusión';

	/// es: 'Canción y oración'
	String get sampleClosingSong => 'Canción y oración';
}

// Path: landing.preview
class Translations$landing$preview$es {
	Translations$landing$preview$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'La vista previa no se parece al PDF. Es el PDF.'
	String get title => 'La vista previa no se parece al PDF. Es el PDF.';

	/// es: 'Los nombres largos caben'
	String get point1Title => 'Los nombres largos caben';

	/// es: 'La columna se ensancha sola.'
	String get point1Body => 'La columna se ensancha sola.';

	/// es: 'Dos semanas en una hoja'
	String get point2Title => 'Dos semanas en una hoja';

	/// es: 'Sin encoger la letra.'
	String get point2Body => 'Sin encoger la letra.';

	/// es: 'La sala auxiliar, al lado'
	String get point3Title => 'La sala auxiliar, al lado';

	/// es: 'En la misma hoja.'
	String get point3Body => 'En la misma hoja.';
}

// Path: landing.features
class Translations$landing$features$es {
	Translations$landing$features$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Sala auxiliar'
	String get auxRoomTitle => 'Sala auxiliar';

	/// es: 'Se queda puesta.'
	String get auxRoomBody => 'Se queda puesta.';

	/// es: 'Visita del circuito'
	String get circuitTitle => 'Visita del circuito';

	/// es: 'Se reordena solo.'
	String get circuitBody => 'Se reordena solo.';

	/// es: 'Cambia lo que quieras'
	String get editTitle => 'Cambia lo que quieras';

	/// es: 'Escribes encima y listo.'
	String get editBody => 'Escribes encima y listo.';

	/// es: 'Te avisa de los huecos'
	String get gapsTitle => 'Te avisa de los huecos';

	/// es: 'Si una semana quedó a medias.'
	String get gapsBody => 'Si una semana quedó a medias.';
}

// Path: landing.privacy
class Translations$landing$privacy$es {
	Translations$landing$privacy$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Tus datos, donde tú digas.'
	String get title => 'Tus datos, donde tú digas.';

	/// es: 'Tú solo'
	String get modeSolo => 'Tú solo';

	/// es: 'En equipo'
	String get modeTeam => 'En equipo';

	/// es: 'Cuenta'
	String get accountLabel => 'Cuenta';

	/// es: 'No hace falta'
	String get accountSolo => 'No hace falta';

	/// es: 'Una por congregación'
	String get accountTeam => 'Una por congregación';

	/// es: 'Dónde están'
	String get whereLabel => 'Dónde están';

	/// es: 'Solo en este dispositivo'
	String get whereSolo => 'Solo en este dispositivo';

	/// es: 'Aquí y en la nube'
	String get whereTeam => 'Aquí y en la nube';

	/// es: 'Quién los ve'
	String get whoSeesLabel => 'Quién los ve';

	/// es: 'Solo tú'
	String get whoSeesSolo => 'Solo tú';

	/// es: 'Tú y los que invites'
	String get whoSeesTeam => 'Tú y los que invites';

	/// es: 'Sin internet'
	String get offlineLabel => 'Sin internet';

	/// es: 'Funciona igual'
	String get offlineSolo => 'Funciona igual';

	/// es: 'Se pone al día al volver'
	String get offlineTeam => 'Se pone al día al volver';

	/// es: 'La contraseña no se puede recuperar. Si la pierdes, se pierde lo que haya en este dispositivo. Haz copias de vez en cuando.'
	String get soloWarning => 'La contraseña no se puede recuperar. Si la pierdes, se pierde lo que haya en este dispositivo. Haz copias de vez en cuando.';

	/// es: 'En la nube va todo cifrado. Pero una copia de la llave se queda en el servidor para que puedas entrar desde otro dispositivo.'
	String get teamNote => 'En la nube va todo cifrado. Pero una copia de la llave se queda en el servidor para que puedas entrar desde otro dispositivo.';
}

// Path: landing.downloads
class Translations$landing$downloads$es {
	Translations$landing$downloads$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Pruébala ahora. Las apps van de camino.'
	String get title => 'Pruébala ahora. Las apps van de camino.';

	/// es: 'La versión de navegador ya funciona.'
	String get body => 'La versión de navegador ya funciona.';

	/// es: 'Abrir Agora ahora'
	String get cta => 'Abrir Agora ahora';

	/// es: 'Próximamente'
	String get comingSoonBadge => 'Próximamente';

	/// es: 'Android, iPhone, iPad, Mac y Windows.'
	String get comingSoonBody => 'Android, iPhone, iPad, Mac y Windows.';

	/// es: 'Google Play'
	String get storeGooglePlayName => 'Google Play';

	/// es: 'Android'
	String get storeGooglePlayPlatforms => 'Android';

	/// es: 'App Store'
	String get storeAppStoreName => 'App Store';

	/// es: 'iPhone y iPad'
	String get storeAppStorePlatforms => 'iPhone y iPad';

	/// es: 'Mac App Store'
	String get storeMacAppStoreName => 'Mac App Store';

	/// es: 'macOS'
	String get storeMacAppStorePlatforms => 'macOS';

	/// es: 'Microsoft Store'
	String get storeMicrosoftStoreName => 'Microsoft Store';

	/// es: 'Windows'
	String get storeMicrosoftStorePlatforms => 'Windows';
}

// Path: landing.footer
class Translations$landing$footer$es {
	Translations$landing$footer$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Herramienta independiente. No está afiliada a la Watch Tower Bible and Tract Society of Pennsylvania ni a ninguna entidad relacionada, y no las representa.'
	String get legal => 'Herramienta independiente. No está afiliada a la Watch Tower Bible and Tract Society of Pennsylvania ni a ninguna entidad relacionada, y no las representa.';

	/// es: 'El código está a la vista en GitHub, pero no es software libre: se puede mirar y usar sin ánimo de lucro (PolyForm Noncommercial 1.0.0). Hecho por Vicente Nevárez Treviño.'
	String get license => 'El código está a la vista en GitHub, pero no es software libre: se puede mirar y usar sin ánimo de lucro (PolyForm Noncommercial 1.0.0). Hecho por Vicente Nevárez Treviño.';

	/// es: 'Enlaces'
	String get linksLabel => 'Enlaces';

	/// es: 'Repositorio en GitHub'
	String get linkRepo => 'Repositorio en GitHub';
}

/// The flat map containing all translations for locale <es>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.brand' => 'Agora',
			'app.defaultProjectName' => 'Programa',
			'portada.tagline' => 'Programas, asignaciones y hermanos de tu congregación, organizados con claridad.',
			'portada.createAccount' => 'Crear cuenta',
			'portada.signIn' => 'Iniciar sesión',
			'portada.noAccountTitle' => 'Continuar sin cuenta',
			'portada.noAccountCaption' => 'Solo en este dispositivo',
			'portada.legal' => 'Herramienta independiente. No está afiliada a la Watch Tower Bible and Tract Society of Pennsylvania ni a sus entidades asociadas.',
			'portada.cloudUnavailable' => 'La nube no está configurada en esta instalación; puedes usar el modo local.',
			'portada.cloudUnsupported' => 'El modo nube no está disponible en este Mac (requiere firma de desarrollador de Apple); puedes usar el modo local.',
			'auth.chooseOther' => 'Elegir otro modo',
			'auth.local.pill' => 'Modo local',
			'auth.local.createTitle' => 'Crea tu perfil local',
			'auth.local.createSub' => 'Se guarda únicamente en este dispositivo.',
			'auth.local.migrateTitle' => 'Protege tus datos',
			'auth.local.migrateSub' => 'Esta versión añade un perfil local: crea una contraseña para proteger los datos que ya tienes en este dispositivo.',
			'auth.local.name' => 'Tu nombre',
			'auth.local.nameHint' => 'Ej. Andrés Beltrán',
			'auth.local.password' => 'Contraseña',
			'auth.local.passwordHint' => 'Mínimo 8 caracteres',
			'auth.local.confirm' => 'Confirmar contraseña',
			'auth.local.confirmHint' => 'Repite la contraseña',
			'auth.local.note1' => 'Tu nombre, contraseña y todos tus datos viven solo aquí. Si olvidas la contraseña ',
			'auth.local.noteBold' => 'no podremos recuperarla',
			'auth.local.note2' => ' — te recomendamos exportar copias de seguridad desde Configuración.',
			'auth.local.createButton' => 'Crear perfil y empezar',
			'auth.local.working' => 'Protegiendo…',
			'auth.local.tooShort' => 'La contraseña debe tener al menos 8 caracteres.',
			'auth.local.mismatch' => 'Las contraseñas no coinciden.',
			'auth.local.profileCaption' => 'Perfil local · este dispositivo',
			'auth.local.unlockButton' => 'Desbloquear',
			'auth.local.unlocking' => 'Descifrando…',
			'auth.local.wrongPassword' => 'Contraseña incorrecta.',
			'auth.local.startOver' => '¿Empezar de cero?',
			'auth.local.createAnother' => 'Crear otro perfil',
			'auth.local.deviceUnlockButton' => 'Usar desbloqueo del dispositivo',
			'auth.cloudLock.title' => 'Sesión bloqueada',
			'auth.cloudLock.caption' => 'Confirma tu identidad para entrar.',
			'auth.cloudLock.unlock' => 'Desbloquear',
			'auth.cloudLock.signOutQuestion' => '¿No eres tú?',
			'auth.cloudLock.signOut' => 'Cerrar sesión',
			'auth.cloudVerify.title' => 'Verifica tu correo',
			'auth.cloudVerify.caption' => ({required Object email}) => 'Te enviamos un enlace a ${email}. Ábrelo para activar tu cuenta — esta pantalla continúa sola en cuanto lo confirmes.',
			'auth.cloudVerify.checkNow' => 'Ya lo verifiqué',
			'auth.cloudVerify.notYetVerified' => 'Todavía no confirmamos tu correo. Revisa tu bandeja de entrada (y spam) y vuelve a intentar.',
			'auth.cloudVerify.resend' => 'Reenviar correo',
			'auth.cloudVerify.resendIn' => ({required Object seconds}) => 'Reenviar en ${seconds}s',
			'auth.cloudVerify.signOutQuestion' => '¿No es tu correo?',
			'auth.cloudVerify.signOut' => 'Cerrar sesión',
			'auth.cloud.pill' => 'Modo nube',
			'auth.cloud.loginTitle' => 'Inicia sesión',
			'auth.cloud.loginSub' => 'Tus congregaciones y proyectos te esperan.',
			'auth.cloud.registerTitle' => 'Crea tu cuenta',
			'auth.cloud.registerSub' => 'Sincroniza y comparte con tu congregación.',
			'auth.cloud.google' => 'Continuar con Google',
			'auth.cloud.orEmail' => 'o con tu correo',
			'auth.cloud.name' => 'Tu nombre',
			'auth.cloud.nameHint' => 'Ej. Andrés Beltrán',
			'auth.cloud.email' => 'Correo',
			'auth.cloud.emailHint' => 'tu@correo.com',
			'auth.cloud.password' => 'Contraseña',
			'auth.cloud.passwordHintLogin' => 'Tu contraseña',
			'auth.cloud.passwordHintRegister' => 'Mínimo 8 caracteres',
			'auth.cloud.confirm' => 'Confirmar contraseña',
			'auth.cloud.confirmHint' => 'Repite la contraseña',
			'auth.cloud.forgot' => '¿Olvidaste tu contraseña?',
			'auth.cloud.backToLogin' => 'Volver a iniciar sesión',
			'auth.cloud.resetTitle' => 'Restablece tu contraseña',
			'auth.cloud.resetSub' => 'Escribe tu correo y te enviaremos un enlace para crear una nueva contraseña.',
			'auth.cloud.resetButton' => 'Enviar enlace',
			'auth.cloud.resetSentTitle' => 'Revisa tu correo',
			'auth.cloud.resetSentDesc' => ({required Object email}) => 'Si existe una cuenta con ${email}, te enviamos un enlace para restablecer tu contraseña.',
			'auth.cloud.resetResend' => 'Reenviar enlace',
			'auth.cloud.resetResendIn' => ({required Object seconds}) => 'Reenviar en ${seconds}s',
			'auth.cloud.loginButton' => 'Iniciar sesión',
			'auth.cloud.registerButton' => 'Crear cuenta',
			'auth.cloud.noAccount' => '¿No tienes cuenta?',
			'auth.cloud.register' => 'Regístrate',
			'auth.cloud.hasAccount' => '¿Ya tienes cuenta?',
			'auth.cloud.login' => 'Inicia sesión',
			'auth.cloud.unavailableTitle' => 'Nube no configurada',
			'auth.cloud.unavailableDesc' => 'Esta instalación no tiene proyecto de Firebase; el modo nube no está disponible.',
			'auth.reset.title' => 'Borrar todos los datos',
			'auth.reset.warning' => 'Sin la contraseña no es posible recuperar la información: se borrarán permanentemente la base de datos local y sus llaves, y empezarás de cero.',
			'auth.reset.confirmPhrase' => 'BORRAR',
			'auth.reset.confirmHint' => ({required Object phrase}) => 'Escribe ${phrase} para confirmar',
			'auth.reset.button' => 'Borrar todo',
			'auth.keyError.title' => 'No se pudo acceder al llavero del sistema',
			'auth.keyError.retry' => 'Reintentar',
			'security.title' => 'Seguridad',
			'security.desc' => 'Cuenta local que protege tus datos cifrados en este dispositivo.',
			'security.changePassword' => 'Cambiar contraseña',
			'security.changePasswordDesc' => 'Vuelve a proteger la llave de cifrado con una contraseña nueva.',
			'security.change' => 'Cambiar',
			'security.current' => 'Contraseña actual',
			'security.newPassword' => 'Contraseña nueva',
			'security.confirmNew' => 'Confirmar contraseña nueva',
			'security.wrongCurrent' => 'La contraseña actual no es correcta.',
			'security.changed' => 'Contraseña actualizada.',
			'security.lockNow' => 'Bloquear ahora',
			'security.lockNowDesc' => 'Cierra la sesión local; pedirá la contraseña al volver.',
			'security.lockNowDescCloud' => 'Bloquea la app; pedirá el desbloqueo del dispositivo al volver.',
			'security.lock' => 'Bloquear',
			'security.descCloud' => 'Protege el acceso a la app en este dispositivo.',
			'security.deviceUnlock' => 'Desbloqueo con el dispositivo',
			'security.deviceUnlockDesc' => 'Entra con Touch ID, Face ID, huella o el código del equipo en lugar de tu contraseña.',
			'security.deviceUnlockDescCloud' => 'Pide Touch ID, Face ID, huella o el código del equipo cada vez que abras la app.',
			'security.deviceUnlockPrompt' => 'Confirma tu identidad para activar el desbloqueo con el dispositivo.',
			'security.unlockPrompt' => 'Desbloquea tus datos de Agora.',
			'security.deviceUnlockKeyMissing' => 'El desbloqueo del dispositivo se desactivó; entra con tu contraseña y actívalo de nuevo.',
			'cloudSync.title' => 'Sincronización en la nube',
			'cloudSync.desc' => 'Tus datos se guardan cifrados y se restauran solos al iniciar sesión en cualquiera de tus dispositivos.',
			'cloudSync.signedOut' => 'Inicia sesión en la nube para activar la sincronización.',
			'cloudSync.unknownError' => 'No se pudo completar. Inténtalo de nuevo.',
			'cloudSync.ready' => 'Sincronización activa',
			'cloudSync.statusSyncing' => 'Sincronizando…',
			'cloudSync.statusOffline' => 'Sin conexión',
			'cloudSync.statusError' => 'Error de sincronización',
			'cloudSync.lastSync' => ({required Object when}) => 'Última sincronización: ${when}',
			'cloudSync.neverSynced' => 'Se sincronizará automáticamente',
			'cloudSync.errorPermission' => 'Ya no tienes acceso a una congregación; tus datos locales se conservan.',
			'cloudSync.errorOffline' => 'Sin conexión; se reintentará automáticamente.',
			'cloudSync.errorUnknown' => 'Ocurrió un error al sincronizar.',
			'cloudSync.restoring' => 'Recuperando tus datos…',
			'cloudSync.restoringProgress' => ({required Object done, required Object total}) => '${done} de ${total} congregaciones',
			'cloudSync.restoreOffline' => 'Sin conexión. Tus datos se recuperarán al reconectar.',
			'account.title' => 'Cuenta en la nube',
			'account.desc' => 'Identidad opcional para sincronizar en el futuro. No sustituye a la contraseña local.',
			'account.notConfigured' => 'Nube no configurada',
			'account.notConfiguredDesc' => 'Esta instalación no tiene proyecto de Firebase: la app funciona 100 % local.',
			'account.signIn' => 'Iniciar sesión',
			'account.register' => 'Crear cuenta',
			'account.google' => 'Continuar con Google',
			'account.or' => 'o',
			'account.email' => 'Correo electrónico',
			'account.password' => 'Contraseña',
			'account.signedInAs' => 'Sesión iniciada',
			'account.signOut' => 'Cerrar sesión',
			'account.localGateNote' => 'Cerrar la sesión de nube no bloquea tus datos locales; para eso usa Seguridad → Bloquear ahora.',
			'account.dangerZone' => 'Zona de peligro',
			'account.deleteAccount' => 'Borrar mi cuenta',
			'account.deleteAccountDesc' => 'Elimina tu cuenta de la nube y todos los datos de este dispositivo.',
			'account.deleteTitle' => 'Borrar mi cuenta',
			'account.deleteWarning' => 'Se borrará tu cuenta de la nube y TODOS los datos de este dispositivo. Esta acción no se puede deshacer. Las congregaciones donde eres el único integrante se eliminarán de la nube; de las demás simplemente saldrás.',
			'account.deleteBlocked' => ({required Object congregations}) => 'No puedes borrar tu cuenta todavía: eres el único administrador de ${congregations}. Pasa el rol de administrador a otra persona o quita a los demás miembros primero.',
			'account.deleteReauthEmail' => 'Confirma tu contraseña para continuar.',
			'account.deleteReauthGoogle' => 'Se te pedirá volver a iniciar sesión con Google para confirmar.',
			'account.deleteConfirm' => 'Borrar mi cuenta',
			'account.deleteError' => 'No se pudo borrar la cuenta. Inténtalo de nuevo.',
			'account.errors.invalidEmail' => 'El correo no es válido.',
			'account.errors.userNotFound' => 'No existe una cuenta con ese correo.',
			'account.errors.wrongPassword' => 'Correo o contraseña incorrectos.',
			'account.errors.emailInUse' => 'Ya existe una cuenta con ese correo.',
			'account.errors.weakPassword' => 'La contraseña es demasiado débil (mínimo 6 caracteres).',
			'account.errors.network' => 'Sin conexión. Inténtalo de nuevo.',
			'account.errors.requiresRecentLogin' => 'Por seguridad, vuelve a iniciar sesión e inténtalo de nuevo.',
			'account.errors.tooManyRequests' => 'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.',
			'account.errors.unknown' => 'No se pudo completar la operación. Inténtalo de nuevo.',
			'nav.home' => 'Inicio',
			'nav.participants' => 'Participantes',
			'nav.settings' => 'Configuración',
			'userMenu.localProfile' => 'Perfil local',
			'userMenu.cloudAccount' => 'Cuenta en la nube',
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
			'common.assigned' => 'asignados',
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
			'dashboard.youHave' => 'Tienes',
			'dashboard.draftsOne' => '1 proyecto en curso',
			'dashboard.draftsMany' => ({required Object n}) => '${n} proyectos en curso',
			'dashboard.newProject' => 'Nuevo proyecto',
			'dashboard.allStatus' => 'Todo estado',
			'dashboard.projects' => 'Tus proyectos',
			'dashboard.reminders' => 'Recordatorios',
			'dashboard.seeAll' => 'Ver todo',
			'dashboard.continueWhere' => 'Continúa donde quedaste',
			'dashboard.continueCta' => 'Continuar',
			'dashboard.assignmentsDone' => ({required Object done, required Object total}) => '${done} de ${total} asignaciones completas',
			'dashboard.pending' => 'Pendientes',
			'dashboard.pendingItem' => ({required Object n}) => '${n} asignaciones pendientes',
			'dashboard.openProject' => 'Abrir proyecto',
			'dashboard.resolvePending' => 'Resolver pendientes',
			'dashboard.allDone' => 'Todo al día ✨',
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
			'participantModal.fullName' => 'Nombre para el programa',
			'participantModal.nameHint' => 'Ej. Martín Salas',
			'participantModal.firstName' => 'Nombre',
			'participantModal.lastName' => 'Apellidos',
			'participantModal.congregation' => 'Congregación de origen',
			'participantModal.originHint' => 'Solo para visitantes; vacío = tu congregación',
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
			'settings.dataDesc' => 'Copia de seguridad cifrada de tus congregaciones, participantes y programas. Útil también para mover datos entre dispositivos.',
			'settings.exportData' => 'Exportar datos',
			'settings.exportDataDesc' => 'Genera un archivo .agora cifrado con contraseña',
			'settings.export' => 'Exportar',
			'settings.importData' => 'Importar datos',
			'settings.importDataDesc' => 'Restaura y fusiona desde un archivo .agora',
			'settings.import' => 'Importar',
			'settings.lastBackup' => 'Última copia',
			'settings.noBackupsYet' => 'Sin copias todavía',
			'settings.backupPasswordTitle' => 'Contraseña de la copia',
			'settings.backupPasswordDesc' => 'Protege el archivo: sin ella no se puede restaurar.',
			'settings.backupPasswordRepeat' => 'Repite la contraseña',
			'settings.backupPasswordMismatch' => 'Las contraseñas no coinciden',
			'settings.backupImportPasswordDesc' => 'La contraseña con la que se exportó el archivo.',
			'settings.backupSaved' => ({required Object path}) => 'Copia guardada: ${path}',
			'settings.backupSharedMsg' => 'Copia compartida',
			'settings.backupRestored' => ({required Object n}) => 'Restauración completa: ${n} registros actualizados',
			'settings.backupWrongPassword' => 'Contraseña incorrecta',
			'settings.backupMalformed' => 'El archivo no es una copia de Agora válida',
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
			'days.monday' => 'Lunes',
			'days.tuesday' => 'Martes',
			'days.wednesday' => 'Miércoles',
			'days.thursday' => 'Jueves',
			'days.friday' => 'Viernes',
			'days.saturday' => 'Sábado',
			'days.sunday' => 'Domingo',
			'months.january' => 'Enero',
			'months.february' => 'Febrero',
			'months.march' => 'Marzo',
			'months.april' => 'Abril',
			'months.may' => 'Mayo',
			'months.june' => 'Junio',
			'months.july' => 'Julio',
			'months.august' => 'Agosto',
			'months.september' => 'Septiembre',
			'months.october' => 'Octubre',
			'months.november' => 'Noviembre',
			'months.december' => 'Diciembre',
			'congregation.dataTitle' => 'Datos de la congregación',
			'congregation.dataDesc' => 'Se usan en el encabezado de los programas.',
			'congregation.name' => 'Nombre',
			'congregation.number' => 'Número',
			'congregation.defaultName' => 'Mi congregación',
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
			'congregation.joinWithCode' => 'Unirse con un código',
			'congregation.you' => 'tú',
			'congregation.roleAdmin' => 'Admin',
			'congregation.roleEditor' => 'Editor',
			'congregation.roleViewer' => 'Lectura',
			'congregation.editAccess' => 'Cambiar permisos',
			'congregation.revoke' => 'Quitar acceso',
			'congregation.revokeTitle' => 'Quitar acceso',
			'congregation.revokeConfirm' => ({required Object name}) => '${name} dejará de recibir cambios. Se generará una clave nueva para el resto y las invitaciones pendientes se cancelarán. Lo que ya tenga descargado seguirá en su dispositivo.',
			'congregation.lastAdmin' => 'Debe quedar al menos una persona con permiso de administración.',
			'congregation.readOnly' => 'Solo tienes acceso de lectura en esta congregación.',
			'congregation.membersError' => 'No se ha podido cargar la lista de miembros.',
			'congregation.pendingLabel' => 'Invitaciones pendientes',
			'congregation.deleteCloud' => 'Borrar datos de la nube',
			'congregation.deleteCloudTitle' => 'Borrar los datos de la nube',
			'congregation.deleteCloudConfirm' => 'Se eliminará el espacio en la nube de esta congregación y TODOS los demás miembros perderán el acceso. Tus datos locales se conservan. Esta acción no se puede deshacer.',
			'congregation.deleteCloudButton' => 'Borrar de la nube',
			'congregation.deleteCloudError' => 'No se pudieron borrar los datos de la nube.',
			'newCongregation.title' => 'Nueva congregación',
			'newCongregation.desc' => 'Serás su administrador. Después podrás invitar usuarios.',
			'newCongregation.create' => 'Crear congregación',
			'newCongregation.name' => 'Nombre',
			'newCongregation.nameHint' => 'Ej. Jardines del Norte',
			'newCongregation.number' => 'Número',
			'newCongregation.numberHint' => 'Ej. 152423',
			'invite.title' => 'Invitar a la congregación',
			'invite.desc' => 'Genera un código y compártelo por un canal privado. Sirve una sola vez.',
			'invite.create' => 'Crear código',
			'invite.capabilities' => 'Permisos',
			'invite.capabilitiesDesc' => 'Lo que podrá hacer quien use el código.',
			'invite.capAdmin' => 'Administrar',
			'invite.capAdminDesc' => 'Miembros, invitaciones y datos de la congregación.',
			'invite.capPeople' => 'Participantes',
			'invite.capPeopleDesc' => 'Editar el directorio de personas.',
			'invite.capPrograms' => 'Programas',
			'invite.capProgramsDesc' => 'Crear y editar proyectos y asignaciones.',
			'invite.codeTitle' => 'Código de invitación',
			'invite.codeDesc' => 'Válido durante 7 días y de un solo uso. Quien lo tenga podrá leer los datos de la congregación: compártelo solo por un canal privado.',
			'invite.copy' => 'Copiar',
			'invite.copied' => 'Código copiado',
			'invite.share' => 'Compartir',
			'invite.done' => 'Hecho',
			'invite.pending' => 'Invitaciones pendientes',
			'invite.expiresOn' => ({required Object date}) => 'Caduca el ${date}',
			'invite.expired' => 'Caducada',
			'invite.cancel' => 'Cancelar invitación',
			'invite.joinTitle' => 'Unirse con un código',
			'invite.joinDesc' => 'Pega el código que te han compartido.',
			'invite.codeLabel' => 'Código',
			'invite.codeHint' => 'agora-inv:1:…',
			'invite.join' => 'Unirse',
			'invite.joined' => 'Te has unido a la congregación.',
			'invite.errorInvalid' => 'Ese código no es válido. Cópialo entero, sin cortarlo.',
			'invite.errorMissing' => 'Esta invitación ya no existe: puede que alguien la haya usado.',
			'invite.errorExpired' => 'Esta invitación ha caducado. Pide una nueva.',
			'invite.errorAlreadyMember' => 'Ya perteneces a esta congregación.',
			'invite.errorKeys' => 'Las claves de sincronización no están disponibles en este dispositivo.',
			'invite.errorUnknown' => 'No se ha podido completar. Inténtalo de nuevo.',
			'invite.paste' => 'Pegar',
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
			'export.exportPdf' => 'Exportar',
			'export.success' => ({required Object path}) => 'Guardado en: ${path}',
			'export.shared' => 'Archivo compartido',
			'export.error' => ({required Object error}) => 'Error al exportar: ${error}',
			'export.formatPdf' => 'PDF',
			'export.formatImage' => 'Imagen',
			'export.saveAction' => 'Guardar',
			'export.shareAction' => 'Compartir',
			'export.currentWeek' => 'Semana actual',
			'export.currentWeekSub' => 'Una semana',
			'export.currentSheet' => 'Hoja actual',
			'export.currentSheetSub' => 'Dos semanas en una hoja',
			'export.noWeeks' => 'Descarga un cuaderno y elige una semana primero.',
			'projectBar.weeks' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '${n} semana', other: '${n} semanas', ), 
			'projectBar.weekN' => ({required Object n}) => 'Semana ${n}',
			'projectBar.goToWeek' => 'Ir a la semana',
			'projectBar.prevWeek' => 'Semana anterior',
			'projectBar.nextWeek' => 'Semana siguiente',
			'projectBar.weekShort' => ({required Object n}) => 'Sem ${n}',
			'projectBar.auxRoom' => 'Sala auxiliar',
			'projectBar.auxRoomDesc' => 'Segunda sala para estudiantes',
			'projectBar.twoPerSheet' => 'Dos por hoja',
			'projectBar.twoPerSheetDesc' => 'Dos semanas en la misma hoja',
			'projectBar.circuitOverseer' => 'Visita del superintendente',
			'projectBar.circuitOverseerDesc' => 'Reemplaza el estudio bíblico por un discurso',
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
			'workspace.slotSpeaker' => 'Orador',
			'workspace.slotAux' => ({required Object label}) => '${label} · Aux.',
			'workspace.editTitle' => 'Editar título',
			'workspace.editTitleHint' => 'Título de la asignación',
			'workspace.restoreTitle' => 'Restablecer',
			'relativeTime.now' => 'ahora mismo',
			'relativeTime.minutes' => ({required Object n}) => 'hace ${n} min',
			'relativeTime.hours' => ({required Object n}) => 'hace ${n} h',
			'relativeTime.days' => ({required Object n}) => 'hace ${n} d',
			'landing.nav.howItWorks' => 'Cómo funciona',
			'landing.nav.schedules' => 'Horarios',
			'landing.nav.privacy' => 'Tus datos',
			'landing.nav.downloads' => 'Descargas',
			'landing.signIn' => 'Iniciar sesión',
			'landing.openApp' => 'Abrir Agora',
			'landing.betaBadge' => 'En pruebas',
			'landing.backToTop' => 'Volver arriba',
			'landing.hero.title' => 'Tú pones los nombres. Ya está.',
			'landing.hero.subtitle' => 'Agora calcula las horas y te deja el PDF listo para imprimir.',
			'landing.hero.cta' => 'Probar ahora',
			'landing.hero.note' => 'Sin cuenta. Sin instalar nada.',
			'landing.howItWorks.title' => 'Son tres pasos.',
			'landing.howItWorks.step1Title' => 'Eliges las semanas',
			'landing.howItWorks.step1Body' => 'La guía ya está descargada, con sus partes y canciones.',
			'landing.howItWorks.step2Title' => 'Pones los nombres',
			'landing.howItWorks.step2Body' => 'Escribes las primeras letras y eliges.',
			'landing.howItWorks.step3Title' => 'Lo imprimes',
			'landing.howItWorks.step3Body' => 'Guardas el PDF o lo compartes.',
			'landing.schedules.title' => 'No vuelvas a sumar minutos a mano.',
			'landing.schedules.body' => 'Cambia una parte y todas las horas de abajo se mueven solas.',
			'landing.schedules.circuit' => '¿Viene el superintendente? Lo marcas y el programa se reordena.',
			'landing.schedules.slack' => 'Sobran 26 min · 8·8·10 a las canciones',
			'landing.schedules.sampleLabel' => 'Semana normal · inicio 18:00',
			'landing.schedules.sampleTargetEnd' => '19:45',
			_ => null,
		} ?? switch (path) {
			'landing.schedules.sampleOpeningSong' => 'Canción y oración',
			'landing.schedules.sampleIntro' => 'Palabras de introducción',
			'landing.schedules.sampleTreasures' => 'Tesoros de la Biblia',
			'landing.schedules.sampleTreasuresDuration' => '25 min',
			'landing.schedules.sampleMinistry' => 'Seamos mejores maestros',
			'landing.schedules.sampleMinistryDuration' => '15 min fijos',
			'landing.schedules.sampleSong2' => 'Canción',
			'landing.schedules.sampleChristianLife' => 'Nuestra vida cristiana',
			'landing.schedules.sampleChristianLifeDuration' => '5 min',
			'landing.schedules.sampleBibleStudy' => 'Estudio bíblico de la congregación',
			'landing.schedules.sampleClosingWords' => 'Palabras de conclusión',
			'landing.schedules.sampleClosingSong' => 'Canción y oración',
			'landing.preview.title' => 'La vista previa no se parece al PDF. Es el PDF.',
			'landing.preview.point1Title' => 'Los nombres largos caben',
			'landing.preview.point1Body' => 'La columna se ensancha sola.',
			'landing.preview.point2Title' => 'Dos semanas en una hoja',
			'landing.preview.point2Body' => 'Sin encoger la letra.',
			'landing.preview.point3Title' => 'La sala auxiliar, al lado',
			'landing.preview.point3Body' => 'En la misma hoja.',
			'landing.features.auxRoomTitle' => 'Sala auxiliar',
			'landing.features.auxRoomBody' => 'Se queda puesta.',
			'landing.features.circuitTitle' => 'Visita del circuito',
			'landing.features.circuitBody' => 'Se reordena solo.',
			'landing.features.editTitle' => 'Cambia lo que quieras',
			'landing.features.editBody' => 'Escribes encima y listo.',
			'landing.features.gapsTitle' => 'Te avisa de los huecos',
			'landing.features.gapsBody' => 'Si una semana quedó a medias.',
			'landing.privacy.title' => 'Tus datos, donde tú digas.',
			'landing.privacy.modeSolo' => 'Tú solo',
			'landing.privacy.modeTeam' => 'En equipo',
			'landing.privacy.accountLabel' => 'Cuenta',
			'landing.privacy.accountSolo' => 'No hace falta',
			'landing.privacy.accountTeam' => 'Una por congregación',
			'landing.privacy.whereLabel' => 'Dónde están',
			'landing.privacy.whereSolo' => 'Solo en este dispositivo',
			'landing.privacy.whereTeam' => 'Aquí y en la nube',
			'landing.privacy.whoSeesLabel' => 'Quién los ve',
			'landing.privacy.whoSeesSolo' => 'Solo tú',
			'landing.privacy.whoSeesTeam' => 'Tú y los que invites',
			'landing.privacy.offlineLabel' => 'Sin internet',
			'landing.privacy.offlineSolo' => 'Funciona igual',
			'landing.privacy.offlineTeam' => 'Se pone al día al volver',
			'landing.privacy.soloWarning' => 'La contraseña no se puede recuperar. Si la pierdes, se pierde lo que haya en este dispositivo. Haz copias de vez en cuando.',
			'landing.privacy.teamNote' => 'En la nube va todo cifrado. Pero una copia de la llave se queda en el servidor para que puedas entrar desde otro dispositivo.',
			'landing.downloads.title' => 'Pruébala ahora. Las apps van de camino.',
			'landing.downloads.body' => 'La versión de navegador ya funciona.',
			'landing.downloads.cta' => 'Abrir Agora ahora',
			'landing.downloads.comingSoonBadge' => 'Próximamente',
			'landing.downloads.comingSoonBody' => 'Android, iPhone, iPad, Mac y Windows.',
			'landing.downloads.storeGooglePlayName' => 'Google Play',
			'landing.downloads.storeGooglePlayPlatforms' => 'Android',
			'landing.downloads.storeAppStoreName' => 'App Store',
			'landing.downloads.storeAppStorePlatforms' => 'iPhone y iPad',
			'landing.downloads.storeMacAppStoreName' => 'Mac App Store',
			'landing.downloads.storeMacAppStorePlatforms' => 'macOS',
			'landing.downloads.storeMicrosoftStoreName' => 'Microsoft Store',
			'landing.downloads.storeMicrosoftStorePlatforms' => 'Windows',
			'landing.footer.legal' => 'Herramienta independiente. No está afiliada a la Watch Tower Bible and Tract Society of Pennsylvania ni a ninguna entidad relacionada, y no las representa.',
			'landing.footer.license' => 'El código está a la vista en GitHub, pero no es software libre: se puede mirar y usar sin ánimo de lucro (PolyForm Noncommercial 1.0.0). Hecho por Vicente Nevárez Treviño.',
			'landing.footer.linksLabel' => 'Enlaces',
			'landing.footer.linkRepo' => 'Repositorio en GitHub',
			'program.song' => ({required Object n}) => 'Canción ${n}',
			'program.openingWords' => 'Palabras de introducción',
			'program.closingWords' => 'Palabras de conclusión',
			'program.circuitOverseerTalk' => 'Discurso del superintendente de circuito',
			'program.partWithDuration' => ({required Object title, required Object n}) => '${title} (${n} mins.)',
			'program.commentsWithDuration' => ({required Object title, required Object n}) => '${title} (${n} min.)',
			'program.roleStudent' => 'Estudiante:',
			'program.roleStudentAssistant' => 'Estudiante/Ayudante:',
			'program.roleConductorReader' => 'Conductor/Lector:',
			'program.rolePrayer' => 'Oración:',
			'program.roleSpeaker' => 'Orador:',
			'program.title' => 'Programa para la reunión de entre semana',
			'program.chairman' => 'Presidente: ',
			'program.mainHall' => 'Auditorio principal',
			'program.auxRoom' => 'Sala Auxiliar',
			'program.sectionTreasures' => 'TESOROS DE LA BIBLIA',
			'program.sectionMinistry' => 'SEAMOS MEJORES MAESTROS',
			'program.sectionChristianLife' => 'NUESTRA VIDA CRISTIANA',
			_ => null,
		};
	}
}
