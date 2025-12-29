import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/get_user_by_id.dart';
import '../../domain/usecases/get_users.dart';

part 'user_event.dart';
part 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final GetUsers getUsers;
  final GetUserById getUserById;

  UserBloc({
    required this.getUsers,
    required this.getUserById,
  }) : super(UserInitial()) {
    on<GetUsersEvent>(_onGetUsers);
    on<GetUserByIdEvent>(_onGetUserById);
  }

  Future<void> _onGetUsers(
    GetUsersEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());

    final result = await getUsers(NoParams());

    result.fold(
      (failure) => emit(UserError(message: failure.message)),
      (users) => emit(UsersLoaded(users: users)),
    );
  }

  Future<void> _onGetUserById(
    GetUserByIdEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());

    final result = await getUserById(GetUserByIdParams(id: event.id));

    result.fold(
      (failure) => emit(UserError(message: failure.message)),
      (user) => emit(UserDetailLoaded(user: user)),
    );
  }
}
