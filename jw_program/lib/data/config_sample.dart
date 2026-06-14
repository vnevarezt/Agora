// Datos de ejemplo de Configuración, portados de `dash-data.js`
// (`users`, `congConfig`). Solo-UI: alimentan la pantalla de configuración
// mientras no haya entidades reales de congregación/usuarios/ajustes.

/// Usuario con acceso a una o varias congregaciones.
typedef UsuarioConfig = ({
  String id,
  String nombre,
  String email,
  String rol,
  List<String> congIds,
});

const usuariosEjemplo = <UsuarioConfig>[
  (
    id: 'u1',
    nombre: 'Andrés Beltrán',
    email: 'andres.b…@gmail.com',
    rol: 'Administrador',
    congIds: ['c1', 'c2', 'c3'],
  ),
  (
    id: 'u2',
    nombre: 'Saúl Bravo',
    email: 'saul.bravo…@gmail.com',
    rol: 'Editor',
    congIds: ['c1'],
  ),
  (
    id: 'u3',
    nombre: 'Tomás Aguilar',
    email: 't.aguilar…@gmail.com',
    rol: 'Editor',
    congIds: ['c2'],
  ),
  (
    id: 'u4',
    nombre: 'Gabriel Núñez',
    email: 'gnu…@gmail.com',
    rol: 'Lector',
    congIds: ['c3'],
  ),
];

/// Horarios/ajustes por congregación (clave = id de congregación).
typedef CongConfig = ({
  String diaEntreSemana,
  String horaEntreSemana,
  String diaFinSemana,
  String horaFinSemana,
  bool salaAuxiliar,
  String idioma,
});

const congConfigEjemplo = <String, CongConfig>{
  'c1': (
    diaEntreSemana: 'Martes',
    horaEntreSemana: '18:00',
    diaFinSemana: 'Domingo',
    horaFinSemana: '10:00',
    salaAuxiliar: false,
    idioma: 'Español',
  ),
  'c2': (
    diaEntreSemana: 'Jueves',
    horaEntreSemana: '19:00',
    diaFinSemana: 'Sábado',
    horaFinSemana: '17:00',
    salaAuxiliar: true,
    idioma: 'Español',
  ),
  'c3': (
    diaEntreSemana: 'Miércoles',
    horaEntreSemana: '19:30',
    diaFinSemana: 'Domingo',
    horaFinSemana: '12:00',
    salaAuxiliar: false,
    idioma: 'Español',
  ),
};

/// Nivel de acceso del usuario actual a cada congregación (para el role-pill
/// del selector). Portado de `congregations[].access`.
const accesoEjemplo = <String, String>{
  'c1': 'Administrador',
  'c2': 'Editor',
  'c3': 'Lector',
};

/// Opciones de los selectores (UI).
const diasSemana = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];
const idiomasReunion = ['Español', 'Lengua de señas', 'English'];
const rolesAcceso = ['Administrador', 'Editor', 'Lector'];
