import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/task_model.dart';
import '../../data/models/company_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/company_repository.dart';
import '../../data/repositories/user_repository.dart';
import 'auth_provider.dart';

class TasksState {
  final List<Task> tasks;
  final bool isLoading;
  final String? error;
  final String? statusFilter;
  final String? assignToUserIdFilter;
  final String? searchQuery;
  final DateTime? startDate;
  final DateTime? endDate;

  const TasksState({
    this.tasks = const [],
    this.isLoading = false,
    this.error,
    this.statusFilter,
    this.assignToUserIdFilter,
    this.searchQuery,
    this.startDate,
    this.endDate,
  });

  TasksState copyWith({
    List<Task>? tasks,
    bool? isLoading,
    String? error,
    String? statusFilter,
    String? assignToUserIdFilter,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool clearSearchQuery = false,
  }) {
    return TasksState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      statusFilter: statusFilter ?? this.statusFilter,
      assignToUserIdFilter: assignToUserIdFilter ?? this.assignToUserIdFilter,
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
    );
  }

  List<Task> get filteredTasks {
    return tasks.where((task) {
      if (statusFilter != null && task.status != statusFilter) return false;
      if (assignToUserIdFilter != null &&
          task.assignToUserId != assignToUserIdFilter) {
        return false;
      }
      // Search filter - task name and company name
      if (searchQuery != null && searchQuery!.isNotEmpty) {
        final query = searchQuery!.toLowerCase();
        final taskNameMatch = task.title.toLowerCase().contains(query);
        final companyNameMatch =
            task.company?.name.toLowerCase().contains(query) ?? false;
        if (!taskNameMatch && !companyNameMatch) return false;
      }
      // Date range filter
      if (startDate != null && task.dueDatetime != null) {
        final taskDate = DateTime(
          task.dueDatetime!.year,
          task.dueDatetime!.month,
          task.dueDatetime!.day,
        );
        final start = DateTime(
          startDate!.year,
          startDate!.month,
          startDate!.day,
        );
        if (taskDate.isBefore(start)) return false;
      }
      if (endDate != null && task.dueDatetime != null) {
        final taskDate = DateTime(
          task.dueDatetime!.year,
          task.dueDatetime!.month,
          task.dueDatetime!.day,
        );
        final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
        if (taskDate.isAfter(end)) return false;
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

// Provider to get filtered tasks based on user role
final userFilteredTasksProvider = Provider<List<Task>>((ref) {
  final tasksState = ref.watch(tasksProvider);
  final currentUserId = ref.watch(currentUserIdProvider);
  final isAdmin = ref.watch(isAdminProvider);

  // Admin sees all tasks, regular users see only their assigned tasks
  if (isAdmin) {
    return tasksState.tasks;
  }

  // Filter tasks where the user is the assignee
  return tasksState.tasks
      .where((task) => task.assignToUserId == currentUserId)
      .toList();
});

// Provider to get filtered pending tasks
final userFilteredPendingTasksProvider = Provider<List<Task>>((ref) {
  final userTasks = ref.watch(userFilteredTasksProvider);
  return userTasks.where((t) => t.status == 'pending').toList();
});

// Provider to get filtered in-progress tasks
final userFilteredInProgressTasksProvider = Provider<List<Task>>((ref) {
  final userTasks = ref.watch(userFilteredTasksProvider);
  return userTasks.where((t) => t.status == 'in_progress').toList();
});

// Provider to get filtered completed tasks
final userFilteredCompletedTasksProvider = Provider<List<Task>>((ref) {
  final userTasks = ref.watch(userFilteredTasksProvider);
  return userTasks.where((t) => t.status == 'completed').toList();
});

class TasksNotifier extends StateNotifier<TasksState> {
  final TaskRepository _taskRepository;
  final CompanyRepository _companyRepository;
  final UserRepository _userRepository;

  TasksNotifier(
    this._taskRepository,
    this._companyRepository,
    this._userRepository,
  ) : super(const TasksState());

  Future<void> loadTasks() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final tasks = await _taskRepository.getTasks();

      // Load company, assignToUser, and assignByUser data for each task
      final tasksWithDetails = await Future.wait(
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

          // Fetch assignToUser details
          User? assignToUser;
          if (task.assignToUserId != null) {
            try {
              assignToUser = await _userRepository.getUserById(
                task.assignToUserId!,
              );
            } catch (e) {
              // Ignore - use existing user data if available
              assignToUser = task.assignToUser;
            }
          }

          // Fetch assignByUser details
          User? assignByUser;
          if (task.assignByUserId != null) {
            try {
              assignByUser = await _userRepository.getUserById(
                task.assignByUserId!,
              );
            } catch (e) {
              // Ignore - use existing user data if available
              assignByUser = task.assignByUser;
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
            assignByUser: assignByUser,
            assignToUserId: task.assignToUserId,
            assignToUser: assignToUser,
            status: task.status,
            actorUserId: task.actorUserId,
            createdAt: task.createdAt,
            updatedAt: task.updatedAt,
          );
        }),
      );

      state = state.copyWith(tasks: tasksWithDetails, isLoading: false);
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

  void setSearchQuery(String? query) {
    state = state.copyWith(
      searchQuery: query,
      clearSearchQuery: query == null || query.isEmpty,
    );
  }

  void setDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(
      startDate: start,
      endDate: end,
      clearStartDate: start == null,
      clearEndDate: end == null,
    );
  }

  void clearFilters() {
    state = state.copyWith(
      statusFilter: null,
      assignToUserIdFilter: null,
      clearSearchQuery: true,
      clearStartDate: true,
      clearEndDate: true,
    );
  }

  /// Helper method to enrich a task with user and company details
  Future<Task> _enrichTaskWithDetails(Task task) async {
    Company? company;
    if (task.companyId != null) {
      try {
        company = await _companyRepository.getCompanyById(task.companyId!);
      } catch (e) {
        company = task.company;
      }
    }

    User? assignToUser;
    if (task.assignToUserId != null) {
      try {
        assignToUser = await _userRepository.getUserById(task.assignToUserId!);
      } catch (e) {
        assignToUser = task.assignToUser;
      }
    }

    User? assignByUser;
    if (task.assignByUserId != null) {
      try {
        assignByUser = await _userRepository.getUserById(task.assignByUserId!);
      } catch (e) {
        assignByUser = task.assignByUser;
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
      assignByUser: assignByUser,
      assignToUserId: task.assignToUserId,
      assignToUser: assignToUser,
      status: task.status,
      actorUserId: task.actorUserId,
      createdAt: task.createdAt,
      updatedAt: task.updatedAt,
    );
  }

  Future<void> createTask({
    required String title,
    String? note,
    required String companyId,
    required DateTime dueDatetime,
    String? assignByUserId,
    String? assignToUserId,
    String? actorUserId,
  }) async {
    try {
      final task = await _taskRepository.createTask(
        title: title,
        note: note,
        companyId: companyId,
        dueDatetime: dueDatetime,
        assignByUserId: assignByUserId,
        assignToUserId: assignToUserId,
        actorUserId: actorUserId,
      );
      // Enrich task with user and company details
      final enrichedTask = await _enrichTaskWithDetails(task);
      state = state.copyWith(tasks: [enrichedTask, ...state.tasks]);
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
      // Enrich task with user and company details
      final enrichedTask = await _enrichTaskWithDetails(task);
      final updatedTasks = state.tasks
          .map((t) => t.id == id ? enrichedTask : t)
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
  final userRepository = ref.watch(userRepositoryProvider);
  return TasksNotifier(taskRepository, companyRepository, userRepository);
});

final taskDetailProvider = FutureProvider.family<Task, String>((ref, id) async {
  final taskRepository = ref.watch(taskRepositoryProvider);
  return taskRepository.getTaskById(id);
});
