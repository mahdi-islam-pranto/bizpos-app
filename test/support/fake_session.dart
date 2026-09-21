import 'package:bizpos_app/core/permissions/permission_set.dart';
import 'package:bizpos_app/core/session/me.dart';
import 'package:bizpos_app/core/session/session_controller.dart';
import 'package:bizpos_app/core/session/session_scope.dart';
import 'package:bizpos_app/core/session/session_state.dart';


/// A session that is simply handed to the app, so widget tests never touch the
/// keystore or the network.
class FakeSessionController extends SessionController {
  FakeSessionController(this._state);

  final SessionState _state;

  @override
  Future<SessionState> build() async => _state;
}

/// Written as an inferred-type function so the test support file does not have
/// to name Riverpod's internal `Override` type, which `flutter_riverpod` does
/// not re-export.
// ignore: prefer_function_declarations_over_variables
final fakeSession = (SessionState state) =>
    sessionControllerProvider.overrideWith(() => FakeSessionController(state));

/// An active session for a person holding [permissions].
SessionState activeSession(
  List<String> permissions, {
  String name = 'Karim',
  String roleName = 'cashier',
  String roleLabel = 'Cashier',
  bool impersonating = false,
  bool isSuperAdmin = false,
  List<MeBranch> branches = const [],
}) =>
    SessionActive(
      me: Me(
        user: MeUser(
          id: 4,
          name: name,
          email: 'someone@rahman.test',
          isSuperAdmin: isSuperAdmin,
        ),
        store: const MeStore(
          id: 1,
          name: 'Rahman Pharmacy',
          slug: 'rahman-pharmacy',
          currency: 'BDT',
          storeTypeName: 'Pharmacy',
        ),
        branch: const MeBranch(id: 1, name: 'Main Branch', code: 'MAIN'),
        stores: const [StoreRef(id: 1, name: 'Rahman Pharmacy')],
        branches: branches,
        role: MeRole(
          id: 4,
          name: roleName,
          label: roleLabel,
          labelBn: 'ক্যাশিয়ার',
        ),
        permissions: PermissionSet(permissions, isSuperAdmin: isSuperAdmin),
        impersonating: impersonating,
      ),
      scope: const SessionScope(storeId: 1, branchId: 1),
    );

/// Signed in, but belonging to no active store.
SessionState noStoreSession() => SessionNoStore(
      Me(
        user: const MeUser(
          id: 9,
          name: 'Rafi',
          email: 'rafi@rahman.test',
          isSuperAdmin: false,
        ),
        store: null,
        branch: null,
        stores: const [],
        branches: const [],
        role: null,
        permissions: const PermissionSet.empty(),
        impersonating: false,
      ),
    );
