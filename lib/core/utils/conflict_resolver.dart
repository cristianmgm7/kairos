import 'package:kairos/core/common/base_classes.dart';

abstract class ConflictResolver {
  const ConflictResolver._();

  static Resolved<T> resolveLatest<T extends HasTimestamps>({required T local, required T remote}) {
    if (remote.updatedAtMillis > local.updatedAtMillis) {
      return ResolvedRemote(remote);
    }

    return ResolvedLocal(local);
  }
}

sealed class Resolved<T> {
  B fold<B>(B Function(T local) ifLocal, B Function(T remote) ifRemote);

  T get value;

  bool get isLocal => this is ResolvedLocal;

  bool get isRemote => this is ResolvedRemote;
}

base class ResolvedLocal<T> extends Resolved<T> {
  ResolvedLocal(this.local);

  final T local;

  @override
  B fold<B>(
    B Function(T local) ifLocal,
    B Function(T remote) ifRemote,
  ) =>
      ifLocal(local);

  @override
  T get value => local;
}

base class ResolvedRemote<T> extends Resolved<T> {
  ResolvedRemote(this.remote);

  final T remote;

  @override
  B fold<B>(
    B Function(T local) ifLocal,
    B Function(T remote) ifRemote,
  ) =>
      ifRemote(remote);

  @override
  T get value => remote;
}
