@extends('layouts.corex')

@section('corex-content')
<div
    x-data="tasksApp()"
    x-init="init()"
    class="relative min-h-screen"
    style="background: var(--bg);"
>
    {{-- ============================================================
         HEADER
         ============================================================ --}}
    <div class="px-4 py-4 md:px-6">
        <div class="flex items-center justify-between">
            <div>
                <h1 class="text-lg font-bold" style="color: var(--text-primary);">Tasks</h1>
                <p class="text-xs mt-0.5" style="color: var(--text-muted);">
                    {{ $summary['open'] }} open &middot;
                    <span style="color: {{ $summary['overdue'] > 0 ? '#ef4444' : 'var(--text-muted)' }};">{{ $summary['overdue'] }} overdue</span>
                </p>
            </div>

            {{-- Desktop view toggle --}}
            <div class="hidden md:flex rounded-md overflow-hidden" style="border: 1px solid var(--border-default);">
                <a
                    href="{{ route('command-center.tasks', ['view' => 'kanban']) }}"
                    class="px-3 py-2 text-xs font-medium transition-colors"
                    style="{{ $currentView === 'kanban' ? 'background: var(--brand-button); color: white;' : 'background: var(--surface); color: var(--text-secondary);' }} touch-action: manipulation;"
                >Kanban</a>
                <a
                    href="{{ route('command-center.tasks', ['view' => 'list']) }}"
                    class="px-3 py-2 text-xs font-medium transition-colors"
                    style="{{ $currentView === 'list' ? 'background: var(--brand-button); color: white;' : 'background: var(--surface); color: var(--text-secondary);' }} touch-action: manipulation;"
                >List</a>
            </div>
        </div>

        {{-- ======== FILTER PILLS ======== --}}
        <div class="flex gap-2 mt-4 overflow-x-auto pb-1 -mx-4 px-4 md:mx-0 md:px-0 scrollbar-hide" style="-webkit-overflow-scrolling: touch;">
            @php
                $filters = [
                    'all' => ['label' => 'All', 'color' => null],
                    'todo' => ['label' => 'To Do', 'color' => '#6b7280'],
                    'in_progress' => ['label' => 'In Progress', 'color' => '#0ea5e9'],
                    'awaiting' => ['label' => 'Awaiting', 'color' => '#f59e0b'],
                    'done' => ['label' => 'Done', 'color' => '#22c55e'],
                    'overdue' => ['label' => 'Overdue', 'color' => '#ef4444'],
                ];
            @endphp
            @foreach($filters as $fKey => $f)
                <button
                    @click="activeFilter = '{{ $fKey }}'"
                    class="px-4 py-2 rounded-md text-xs font-medium whitespace-nowrap shrink-0 transition-all duration-200"
                    :class="activeFilter === '{{ $fKey }}' ? 'ring-1' : 'opacity-60'"
                    :style="activeFilter === '{{ $fKey }}'
                        ? 'background: {{ $f['color'] ? $f['color'] . '20' : 'var(--brand-default)' }}; color: {{ $f['color'] ?? 'var(--brand-button)' }}; ring-color: {{ $f['color'] ?? 'var(--brand-button)' }};'
                        : 'background: var(--surface); color: var(--text-secondary);'"
                    style="min-height: 44px; touch-action: manipulation;"
                >
                    @if($f['color'])
                        <span class="inline-block w-1.5 h-1.5 rounded-full mr-1" style="background: {{ $f['color'] }};"></span>
                    @endif
                    {{ $f['label'] }}
                </button>
            @endforeach
        </div>
    </div>

    {{-- ============================================================
         MOBILE LIST VIEW (default on mobile, also shown on desktop list)
         ============================================================ --}}
    <div class="md:hidden px-4 pb-24 space-y-2" x-show="true">
        @php
            $allTasks = collect();
            foreach ($columns as $status => $tasks) {
                foreach ($tasks as $task) {
                    $allTasks->push($task);
                }
            }
        @endphp

        @foreach($allTasks as $task)
            @php
                $statusMap = ['todo' => 'todo', 'in_progress' => 'in_progress', 'awaiting' => 'awaiting', 'done' => 'done'];
                $taskStatus = $task->status ?? 'todo';
                $isOverdue = $task->isOverdue();
            @endphp
            <div
                x-show="activeFilter === 'all'
                    || activeFilter === '{{ $taskStatus }}'
                    || (activeFilter === 'overdue' && {{ $isOverdue ? 'true' : 'false' }})"
                x-data="{ expanded: false }"
            >
                @include('command-center.partials.swipeable-card', [
                    'id' => 'mtask-' . $task->id,
                    'rightAction' => [
                        'label' => 'Complete',
                        'color' => '#22c55e',
                        'icon' => '<svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7"/></svg>',
                        'action' => "fetch('" . route('command-center.tasks.complete', $task->id) . "', {method:'POST',headers:{'X-CSRF-TOKEN':document.querySelector('meta[name=csrf-token]').content}}).then(()=>location.reload())",
                    ],
                    'leftAction' => [
                        'label' => 'Options',
                        'color' => '#6b7280',
                        'icon' => '<svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M12 5v.01M12 12v.01M12 19v.01M12 6a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z"/></svg>',
                        'action' => "expanded = !expanded; reset()",
                    ],
                ])
                @slot('slot')
                    <div @click="expanded = !expanded" class="p-4 cursor-pointer" style="touch-action: manipulation; min-height: 64px;">
                        <div class="flex items-start gap-3">
                            {{-- Status indicator --}}
                            @php
                                $statusColors = ['todo' => '#6b7280', 'in_progress' => '#0ea5e9', 'awaiting' => '#f59e0b', 'done' => '#22c55e'];
                                $sc = $statusColors[$taskStatus] ?? '#6b7280';
                                $prioColors = ['low' => '#6b7280', 'normal' => '#0ea5e9', 'high' => '#f59e0b', 'critical' => '#ef4444'];
                                $pc = $prioColors[$task->priority] ?? '#6b7280';
                            @endphp
                            <div class="w-2 h-2 rounded-full shrink-0 mt-1.5" style="background: {{ $isOverdue ? '#ef4444' : $sc }};"></div>

                            <div class="flex-1 min-w-0">
                                <p class="text-sm font-medium" style="color: var(--text-primary); {{ $taskStatus === 'done' ? 'text-decoration: line-through; opacity: 0.6;' : '' }}">
                                    {{ $task->title }}
                                </p>
                                @if($task->property)
                                    <p class="text-xs mt-0.5 truncate" style="color: var(--text-secondary);">
                                        {{ $task->property->buildDisplayAddress() }}
                                    </p>
                                @endif
                            </div>

                            <div class="flex flex-col items-end gap-1 shrink-0">
                                <span class="text-[10px] px-1.5 py-0.5 rounded" style="background: {{ $pc }}20; color: {{ $pc }};">
                                    {{ ucfirst($task->priority) }}
                                </span>
                                @if($task->due_date)
                                    <span class="text-[10px]" style="color: {{ $isOverdue ? '#ef4444' : 'var(--text-muted)' }};">
                                        {{ \Carbon\Carbon::parse($task->due_date)->format('j M') }}
                                    </span>
                                @endif
                            </div>
                        </div>

                        {{-- Expanded detail --}}
                        <div x-show="expanded" x-transition class="mt-3 pt-3" style="border-top: 1px solid var(--border-default);" @click.stop>
                            @if($task->description)
                                <p class="text-xs mb-3" style="color: var(--text-secondary);">{{ $task->description }}</p>
                            @endif

                            <div class="flex flex-wrap gap-2">
                                @if($taskStatus !== 'done')
                                    {{-- Status actions --}}
                                    @if($taskStatus !== 'in_progress')
                                        <form action="{{ route('command-center.tasks.update-status', $task->id) }}" method="POST" class="inline">
                                            @csrf
                                            @method('PATCH')
                                            <input type="hidden" name="status" value="in_progress">
                                            <button type="submit" class="px-3 py-2 rounded-md text-xs font-medium" style="background: #0ea5e920; color: #0ea5e9; min-height: 40px; touch-action: manipulation;">
                                                In Progress
                                            </button>
                                        </form>
                                    @endif
                                    <form action="{{ route('command-center.tasks.complete', $task->id) }}" method="POST" class="inline">
                                        @csrf
                                        <button type="submit" class="px-3 py-2 rounded-md text-xs font-medium" style="background: #22c55e20; color: #22c55e; min-height: 40px; touch-action: manipulation;">
                                            Complete
                                        </button>
                                    </form>
                                    <form action="{{ route('command-center.resolve-task', $task->id) }}" method="POST" class="inline">
                                        @csrf
                                        <input type="hidden" name="resolution" value="did_not_happen">
                                        <button type="submit" class="px-3 py-2 rounded-md text-xs font-medium" style="background: var(--surface-2); color: var(--text-muted); min-height: 40px; touch-action: manipulation;">
                                            Did Not Happen
                                        </button>
                                    </form>
                                @endif
                                <form action="{{ route('command-center.tasks.destroy', $task->id) }}" method="POST" class="inline"
                                      onsubmit="return confirm('Delete this task?')">
                                    @csrf
                                    @method('DELETE')
                                    <button type="submit" class="px-3 py-2 rounded-md text-xs font-medium" style="background: #ef444420; color: #ef4444; min-height: 40px; touch-action: manipulation;">
                                        Delete
                                    </button>
                                </form>
                            </div>
                        </div>
                    </div>
                @endslot
            </div>
        @endforeach

        {{-- Empty state --}}
        @if($allTasks->isEmpty())
            <div class="text-center py-16">
                <div class="w-16 h-16 mx-auto mb-3 rounded-full flex items-center justify-center" style="background: var(--surface);">
                    <svg class="w-8 h-8" style="color: var(--text-muted);" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/>
                    </svg>
                </div>
                <p class="text-sm font-medium" style="color: var(--text-secondary);">No tasks yet</p>
                <button
                    @click="createOpen = true"
                    class="mt-3 text-sm font-medium px-4 py-2.5 rounded-md"
                    style="color: var(--brand-button); background: rgba(14,165,233,0.1); touch-action: manipulation; min-height: 44px;"
                >+ Add Task</button>
            </div>
        @endif
    </div>

    {{-- ============================================================
         DESKTOP KANBAN VIEW
         ============================================================ --}}
    <div class="hidden md:block px-6 pb-6">
        <div class="grid grid-cols-4 gap-4">
            @php
                $statusLabels = ['todo' => 'To Do', 'in_progress' => 'In Progress', 'awaiting' => 'Awaiting', 'done' => 'Done'];
                $statusColors = ['todo' => '#6b7280', 'in_progress' => '#0ea5e9', 'awaiting' => '#f59e0b', 'done' => '#22c55e'];
            @endphp
            @foreach($columns as $status => $tasks)
                <div class="rounded-md overflow-hidden" style="background: var(--surface); border: 1px solid var(--border-default);">
                    {{-- Column header --}}
                    <div class="flex items-center justify-between px-4 py-3" style="border-bottom: 1px solid var(--border-default);">
                        <div class="flex items-center gap-2">
                            <span class="w-2 h-2 rounded-full" style="background: {{ $statusColors[$status] ?? '#6b7280' }};"></span>
                            <span class="text-xs font-semibold" style="color: var(--text-primary);">{{ $statusLabels[$status] ?? ucfirst($status) }}</span>
                        </div>
                        <span class="text-xs px-2 py-0.5 rounded-full" style="background: var(--surface-2); color: var(--text-muted);">{{ $tasks->count() }}</span>
                    </div>

                    {{-- Column content --}}
                    <div class="p-2 space-y-2 max-h-[70vh] overflow-y-auto" style="-webkit-overflow-scrolling: touch;">
                        @foreach($tasks as $task)
                            @php
                                $pc = $prioColors[$task->priority] ?? '#6b7280';
                                $isOverdue = $task->isOverdue();
                            @endphp
                            <div
                                x-data="{ showActions: false }"
                                class="rounded-md p-3 transition-colors cursor-pointer"
                                style="background: var(--bg); border: 1px solid {{ $isOverdue ? '#ef444440' : 'var(--border-default)' }};"
                                @click="showActions = !showActions"
                            >
                                <div class="flex items-start justify-between gap-2">
                                    <p class="text-xs font-medium leading-snug" style="color: var(--text-primary);">{{ $task->title }}</p>
                                    <span class="text-[9px] px-1 py-0.5 rounded shrink-0" style="background: {{ $pc }}20; color: {{ $pc }};">
                                        {{ ucfirst($task->priority) }}
                                    </span>
                                </div>
                                @if($task->property)
                                    <p class="text-[10px] mt-1 truncate" style="color: var(--text-muted);">
                                        {{ $task->property->buildDisplayAddress() }}
                                    </p>
                                @endif
                                @if($task->due_date)
                                    <p class="text-[10px] mt-1" style="color: {{ $isOverdue ? '#ef4444' : 'var(--text-muted)' }};">
                                        {{ \Carbon\Carbon::parse($task->due_date)->format('j M Y') }}
                                        @if($isOverdue) &middot; Overdue @endif
                                    </p>
                                @endif

                                {{-- Inline actions --}}
                                <div x-show="showActions" x-transition class="mt-2 pt-2 flex flex-wrap gap-1" style="border-top: 1px solid var(--border-default);" @click.stop>
                                    @if($status !== 'done')
                                        @foreach(['todo' => 'To Do', 'in_progress' => 'In Progress', 'awaiting' => 'Awaiting', 'done' => 'Done'] as $s => $sl)
                                            @if($s !== $status)
                                                <form action="{{ route('command-center.tasks.update-status', $task->id) }}" method="POST" class="inline">
                                                    @csrf
                                                    @method('PATCH')
                                                    <input type="hidden" name="status" value="{{ $s }}">
                                                    <button type="submit" class="px-2 py-1 rounded text-[10px] font-medium"
                                                            style="background: {{ $statusColors[$s] ?? '#6b7280' }}15; color: {{ $statusColors[$s] ?? '#6b7280' }};">
                                                        {{ $sl }}
                                                    </button>
                                                </form>
                                            @endif
                                        @endforeach
                                    @endif
                                </div>
                            </div>
                        @endforeach
                    </div>
                </div>
            @endforeach
        </div>
    </div>

    {{-- ============================================================
         CREATE TASK BOTTOM SHEET
         ============================================================ --}}
    <div x-data="{ open: createOpen, sheetTouchStartY: 0, sheetScrollTop: 0 }" x-effect="open = createOpen" @open-create-task.window="createOpen = true">
        <div
            x-show="createOpen"
            x-transition:enter="transition ease-out duration-300"
            x-transition:enter-start="opacity-0"
            x-transition:enter-end="opacity-100"
            x-transition:leave="transition ease-in duration-200"
            class="fixed inset-0 z-[60] flex items-end justify-center"
            @keydown.escape.window="createOpen = false"
        >
            <div class="absolute inset-0 bg-black/60 backdrop-blur-sm" @click="createOpen = false"></div>
            <div
                x-show="createOpen"
                x-transition:enter="transition ease-out duration-300 transform"
                x-transition:enter-start="translate-y-full"
                x-transition:enter-end="translate-y-0"
                x-transition:leave="transition ease-in duration-200 transform"
                x-transition:leave-start="translate-y-0"
                x-transition:leave-end="translate-y-full"
                class="relative w-full max-w-lg rounded-t-2xl overflow-hidden flex flex-col"
                style="background: var(--surface); max-height: 85vh; padding-bottom: env(safe-area-inset-bottom, 0px);"
            >
                <div class="flex justify-center pt-3 pb-1 shrink-0">
                    <div class="w-10 h-1 rounded-full" style="background: var(--text-muted);"></div>
                </div>
                <div class="flex items-center justify-between px-5 pb-3 shrink-0" style="border-bottom: 1px solid var(--border-default);">
                    <h3 class="text-base font-semibold" style="color: var(--text-primary);">New Task</h3>
                    <button @click="createOpen = false" class="w-8 h-8 flex items-center justify-center rounded-full" style="background: var(--surface-2); color: var(--text-secondary); touch-action: manipulation;">
                        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/></svg>
                    </button>
                </div>
                <div class="flex-1 overflow-y-auto px-5 py-4" style="-webkit-overflow-scrolling: touch;">
                    <form action="{{ route('command-center.tasks.store') }}" method="POST" class="space-y-4">
                        @csrf
                        <div>
                            <input
                                type="text"
                                name="title"
                                placeholder="Task title"
                                required
                                autofocus
                                class="w-full rounded-md px-4 py-3 text-sm"
                                style="background: var(--surface-2); color: var(--text-primary); border: 1px solid var(--border-default); min-height: 48px;"
                            >
                        </div>

                        <div>
                            <label class="text-xs font-medium mb-2 block" style="color: var(--text-secondary);">Priority</label>
                            @include('command-center.partials.priority-pills')
                        </div>

                        <div>
                            <label class="text-xs font-medium mb-2 block" style="color: var(--text-secondary);">Type</label>
                            <select name="task_type" class="w-full rounded-md px-4 py-3 text-sm" style="background: var(--surface-2); color: var(--text-primary); border: 1px solid var(--border-default); min-height: 48px;">
                                <option value="custom">Custom</option>
                                <option value="follow_up">Follow Up</option>
                                <option value="document_upload">Document Upload</option>
                                <option value="compliance">Compliance</option>
                                <option value="review">Review</option>
                                <option value="deal_action">Deal Action</option>
                            </select>
                        </div>

                        <div>
                            <label class="text-xs font-medium mb-2 block" style="color: var(--text-secondary);">Due Date</label>
                            <input type="date" name="due_date" class="w-full rounded-md px-4 py-3 text-sm" style="background: var(--surface-2); color: var(--text-primary); border: 1px solid var(--border-default); min-height: 48px;">
                        </div>

                        <div>
                            <textarea name="description" placeholder="Description (optional)" rows="2" class="w-full rounded-md px-4 py-3 text-sm resize-none" style="background: var(--surface-2); color: var(--text-primary); border: 1px solid var(--border-default);"></textarea>
                        </div>

                        <label class="flex items-center gap-3 py-1 cursor-pointer" style="touch-action: manipulation;">
                            <div class="relative">
                                <input type="hidden" name="send_reminder" value="0">
                                <input type="checkbox" name="send_reminder" value="1" checked class="sr-only peer">
                                <div class="w-11 h-6 rounded-full transition-colors duration-200 peer-checked:bg-[#0ea5e9]" style="background: var(--surface-2);"></div>
                                <div class="absolute left-0.5 top-0.5 w-5 h-5 bg-white rounded-full shadow transition-transform duration-200 peer-checked:translate-x-5"></div>
                            </div>
                            <span class="text-sm" style="color: var(--text-secondary);">Send reminder</span>
                        </label>

                        <button type="submit" class="w-full py-3.5 rounded-md text-sm font-semibold text-white" style="background: var(--brand-button); min-height: 48px; touch-action: manipulation;">
                            Add Task
                        </button>
                    </form>
                </div>
            </div>
        </div>
    </div>

    {{-- ============================================================
         MOBILE FAB
         ============================================================ --}}
    <button
        @click="createOpen = true"
        class="fixed bottom-6 right-5 z-50 w-14 h-14 rounded-full flex items-center justify-center shadow-lg shadow-sky-500/25 md:hidden transition-transform active:scale-90"
        style="background: var(--brand-button); color: white; touch-action: manipulation;"
    >
        <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4"/>
        </svg>
    </button>
</div>

<script>
function tasksApp() {
    return {
        activeFilter: 'all',
        createOpen: false,

        init() {}
    };
}
</script>

<style>
    .scrollbar-hide::-webkit-scrollbar { display: none; }
    .scrollbar-hide { -ms-overflow-style: none; scrollbar-width: none; }
</style>
@endsection
