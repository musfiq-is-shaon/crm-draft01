import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/task_model.dart';
import '../../data/models/company_model.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/company_repository.dart';

class TasksState {
  final List<Task> tasks;
  final bool isLoading;
  final String? error;
  final String? statusFilter;
  final String? assignToUserIdFilter;

  const TasksState({
    this.tasks = const [],
    this.isLoading = false,
    this.error,
    this.statusFilter,
    this.assignToUserIdFilter,
  });

  TasksState copyWith({
    List<Task>? tasks,
    bool? isLoading,
    String? error,
    String? statusFilter,
    String? assignToUserIdFilter,
  }) {
    return TasksState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      statusFilter: statusFilter ?? this.statusFilter,
      assignToUserIdFilter: assignToUserIdFilter ?? this.assignToUserIdFilter,
    );
  }

  List<Task> get filteredTasks {
    return tasks.where((task) {
      if (statusFilter != null && task.status != statusFilter) return false;
      if (assignToUserIdFilter != null &&
          task.assignToUserId != assignToUserIdFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  List<Task> get pendingTasks =>
      tasks.where((t) => t.status == 'pending').toList();
  List<Task> get inProgressTasks =>
      tasks.where((t) => t.status == 'in_progress').toList();
  List<Task> get completedTasks =>
      tasks.where((t) => t.status == 'completed').toList();
  List<Task> get overdueTasks => tasks.where((t) => t.isOverdue).toList();
}

class TasksNotifier extends StateNotifier<TasksState> {
  final TaskRepository _taskRepository;
  final CompanyRepository _companyRepository;

  TasksNotifier(this._taskRepository, this._companyRepository)
    : super(const TasksState());

  Future<void> loadTasks() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final tasks = await _taskRepository.getTasks();

      // Load company with KAM data for each task
      final tasksWithCompany = await Future.wait(
        tasks.map((task) async {
          Company? company;
          if (task.companyId != null) {
            try {
              company = await _companyRepository.getCompanyById(
                task.companyId!,
              );
            } catch (e) {
              // Ignore - use existing company data if available
              company = task.company;
            }
          }
          return Task(
            id: task.id,
            title: task.title,
            note: task.note,
            companyId: task.companyId,
            company: company,
            dueDatetime: task.dueDatetime,
            assignByUserId: task.assignByUserId,
            assignByUser: task.assignByUser,
            assignToUserId: task.assignToUserId,
            assignToUser: task.assignToUser,
            status: task.status,
            actorUserId: task.actorUserId,
            createdAt: task.createdAt,
            updatedAt: task.updatedAt,
          );
        }),
      );

      state = state.copyWith(tasks: tasksWithCompany, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setStatusFilter(String? status) {
    state = state.copyWith(statusFilter: status);
  }

  void setAssigneeFilter(String? userId) {
    state = state.copyWith(assignToUserIdFilter: userId);
  }

  void clearFilters() {
    state = state.copyWith(statusFilter: null, assignToUserIdFilter: null);
  }

  Future<void> createTask({
    required String title,
    String? note,
    required String companyId,
    required DateTime dueDatetime,
    String? assignByUserId,
    String? assignToUserId,
  }) async {
    try {
      final task = await _taskRepository.createTask(
        title: title,
        note: note,
        companyId: companyId,
        dueDatetime: dueDatetime,
        assignByUserId: assignByUserId,
        assignToUserId: assignToUserId,
      );
      state = state.copyWith(tasks: [task, ...state.tasks]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateTask({
    required String id,
    String? title,
    String? note,
    String? companyId,
    DateTime? dueDatetime,
    String? assignByUserId,
    String? assignToUserId,
  }) async {
    try {
      final task = await _taskRepository.updateTask(
        id: id,
        title: title,
        note: note,
        companyId: companyId,
        dueDatetime: dueDatetime,
        assignByUserId: assignByUserId,
        assignToUserId: assignToUserId,
      );
      final updatedTasks = state.tasks
          .map((t) => t.id == id ? task : t)
          .toList();
      state = state.copyWith(tasks: updatedTasks);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> changeTaskStatus({
    required String id,
    required String status,
    String? note,
  }) async {
    try {
      final task = await _taskRepository.changeTaskStatus(
        id: id,
        status: status,
        note: note,
      );
      final updatedTasks = state.tasks
          .map((t) => t.id == id ? task : t)
          .toList();
      state = state.copyWith(tasks: updatedTasks);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await _taskRepository.deleteTask(id);
      final updatedTasks = state.tasks.where((t) => t.id != id).toList();
      state = state.copyWith(tasks: updatedTasks);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final tasksProvider = StateNotifierProvider<TasksNotifier, TasksState>((ref) {
  final taskRepository = ref.watch(taskRepositoryProvider);
  final companyRepository = ref.watch(companyRepositoryProvider);
  return TasksNotifier(taskRepository, companyRepository);
});

final taskDetailProvider = FutureProvider.family<Task, String>((ref, id) async {
  final taskRepository = ref.watch(taskRepositoryProvider);
  return taskRepository.getTaskById(id);
});
