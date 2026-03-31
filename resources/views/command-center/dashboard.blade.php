@extends('layouts.corex')

@section('corex-content')
<div
    x-data="commandDashboard()"
    x-init="init()"
    class="relative min-h-screen"
    style="background: var(--bg); padding-bottom: 100px;"
>
    {{-- ============================================================
         OVERDUE REVIEW OVERLAY (full-screen mobile, modal desktop)
         ============================================================ --}}
    <div
        x-show="overdueOpen && overdueItems.length > 0"
        x-transition:enter="transition ease-out duration-300"
        x-transition:enter-start="opacity-0"
        x-transition:enter-end="opacity-100"
        x-transition:leave="transition ease-in duration-200"
        class="fixed inset-0 z-[70] flex items-center justify-center"
        style="background: rgba(0,0,0,0.85); backdrop-filter: blur(8px); -webkit-backdrop-filter: blur(8px);"
    >
        <div class="w-full h-full md:h-auto md:max-h-[90vh] md:max-w-lg md:rounded-xl overflow-hidden flex flex-col" style="background: var(--surface);">
            {{-- Header --}}
            <div class="flex items-center justify-between px-5 py-4 shrink-0" style="border-bottom: 1px solid var(--border-default);">
                <div>
                    <h2 class="text-lg font-bold" style="color: var(--text-primary);">Overdue Review</h2>
                    <p class="text-xs mt-0.5" style="color: var(--text-secondary);">
                        <span x-text="resolvedCount"></span> of <span x-text="overdueItems.length"></span> resolved
                    </p>
                </div>
                <button
                    @click="overdueOpen = false"
                    class="w-10 h-10 flex items-center justify-center rounded-full transition-colors"
                    style="background: var(--surface-2); color: var(--text-secondary); touch-action: manipulation;"
                >
                    <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
                    </svg>
                </button>
            </div>

            {{-- Progress bar --}}
            <div class="h-1 w-full" style="background: var(--surface-2);">
                <div
                    class="h-full transition-all duration-500 ease-out rounded-r"
                    style="background: var(--brand-button);"
                    :style="`width: ${overdueItems.length > 0 ? (resolvedCount / overdueItems.length * 100) : 0}%`"
                ></div>
            </div>

            {{-- Card stack --}}
            <div class="flex-1 overflow-y-auto px-5 py-4" style="-webkit-overflow-scrolling: touch;">
                <template x-for="(item, idx) in overdueItems" :key="item.id + '-' + item.type">
                    <div
                        x-show="currentOverdueIdx === idx"
                        x-transition:enter="transition ease-out duration-200"
                        x-transition:enter-start="opacity-0 translate-x-4"
                        x-transition:enter-end="opacity-100 translate-x-0"
                        class="space-y-4"
                    >
                        {{-- Card --}}
                        <div class="rounded-md overflow-hidden" style="border: 1px solid var(--border-default);">
                            <div class="h-1" :style="`background: ${item.colour || '#6b7280'}`"></div>
                            <div class="p-4 space-y-2">
                                <div class="flex items-start justify-between gap-3">
                                    <h3 class="text-sm font-semibold leading-snug" style="color: var(--text-primary);" x-text="item.title"></h3>
                                    <span
                                        class="text-[10px] font-medium px-2 py-0.5 rounded shrink-0"
                                        :style="`background: ${item.colour || '#6b7280'}20; color: ${item.colour || '#6b7280'};`"
                                        x-text="item.typeLabel"
                                    ></span>
                                </div>
                                <p
                                    x-show="item.address"
                                    class="text-xs flex items-center gap-1"
                                    style="color: var(--text-secondary);"
                                >
                                    <svg class="w-3.5 h-3.5 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                        <path stroke-linecap="round" stroke-linejoin="round" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"/>
                                        <path stroke-linecap="round" stroke-linejoin="round" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"/>
                                    </svg>
                                    <span x-text="item.address"></span>
                                </p>
                                <p class="text-xs" style="color: #ef4444;">
                                    <span x-text="item.overdueSince"></span> overdue
                                </p>
                            </div>
                        </div>

                        {{-- Resolution form --}}
                        <form
                            :action="item.resolveUrl"
                            method="POST"
                            class="space-y-2"
                            @submit="item.resolved = true; resolvedCount++; $nextTick(() => { if(currentOverdueIdx < overdueItems.length - 1) currentOverdueIdx++ })"
                        >
                            @csrf
                            <input type="hidden" name="resolution" x-model="item.resolution">
                            <input type="hidden" name="extend_days" x-model="item.extendDays">
                            <input type="hidden" name="resolution_note" x-model="item.note">

                            {{-- Completed --}}
                            <button
                                type="submit"
                                @click="item.resolution = 'completed'"
                                class="w-full flex items-center gap-3 px-4 py-3.5 rounded-md text-sm font-medium transition-colors"
                                style="background: rgba(34,197,94,0.1); color: #22c55e; touch-action: manipulation; min-height: 48px;"
                            >
                                <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                    <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7"/>
                                </svg>
                                Completed
                            </button>

                            {{-- Extend Time --}}
                            <div>
                                <button
                                    type="button"
                                    @click="item.showExtend = !item.showExtend"
                                    class="w-full flex items-center gap-3 px-4 py-3.5 rounded-md text-sm font-medium transition-colors"
                                    style="background: rgba(14,165,233,0.1); color: #0ea5e9; touch-action: manipulation; min-height: 48px;"
                                >
                                    <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                        <path stroke-linecap="round" stroke-linejoin="round" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/>
                                    </svg>
                                    Extend Time
                                    <svg class="w-4 h-4 ml-auto transition-transform" :class="item.showExtend && 'rotate-180'" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                        <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7"/>
                                    </svg>
                                </button>
                                <div x-show="item.showExtend" x-transition class="mt-2 flex items-center gap-2 px-4">
                                    <label class="text-xs shrink-0" style="color: var(--text-secondary);">Days:</label>
                                    <select
                                        x-model="item.extendDays"
                                        class="flex-1 rounded-md text-sm px-3 py-2.5"
                                        style="background: var(--surface-2); color: var(--text-primary); border: 1px solid var(--border-default); min-height: 44px;"
                                    >
                                        <option value="1">1 day</option>
                                        <option value="2">2 days</option>
                                        <option value="3">3 days</option>
                                        <option value="5">5 days</option>
                                        <option value="7">1 week</option>
                                        <option value="14">2 weeks</option>
                                    </select>
                                    <button
                                        type="submit"
                                        @click="item.resolution = 'extended'"
                                        class="px-4 py-2.5 rounded-md text-sm font-medium text-white"
                                        style="background: var(--brand-button); min-height: 44px; touch-action: manipulation;"
                                    >
                                        Extend
                                    </button>
                                </div>
                            </div>

                            {{-- Did Not Take Place --}}
                            <button
                                type="submit"
                                @click="item.resolution = 'did_not_happen'"
                                class="w-full flex items-center gap-3 px-4 py-3.5 rounded-md text-sm font-medium transition-colors"
                                style="background: var(--surface-2); color: var(--text-secondary); touch-action: manipulation; min-height: 48px;"
                            >
                                <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                    <path stroke-linecap="round" stroke-linejoin="round" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636"/>
                                </svg>
                                Did Not Take Place
                            </button>
                        </form>

                        {{-- Navigation --}}
                        <div class="flex items-center justify-between pt-2">
                            <button
                                @click="if(currentOverdueIdx > 0) currentOverdueIdx--"
                                :disabled="currentOverdueIdx === 0"
                                class="text-xs px-3 py-2 rounded-md disabled:opacity-30"
                                style="color: var(--text-secondary); touch-action: manipulation; min-height: 44px;"
                            >&larr; Previous</button>
                            <span class="text-xs" style="color: var(--text-muted);" x-text="`${currentOverdueIdx + 1} / ${overdueItems.length}`"></span>
                            <button
                                @click="if(currentOverdueIdx < overdueItems.length - 1) currentOverdueIdx++"
                                :disabled="currentOverdueIdx >= overdueItems.length - 1"
                                class="text-xs px-3 py-2 rounded-md disabled:opacity-30"
                                style="color: var(--text-secondary); touch-action: manipulation; min-height: 44px;"
                            >Next &rarr;</button>
                        </div>
                    </div>
                </template>

                {{-- All resolved --}}
                <div x-show="resolvedCount >= overdueItems.length && overdueItems.length > 0" class="text-center py-8 space-y-3">
                    <div class="w-16 h-16 mx-auto rounded-full flex items-center justify-center" style="background: rgba(34,197,94,0.1);">
                        <svg class="w-8 h-8" style="color: #22c55e;" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7"/>
                        </svg>
                    </div>
                    <p class="text-sm font-medium" style="color: var(--text-primary);">All caught up!</p>
                    <button @click="overdueOpen = false" class="text-sm px-6 py-2.5 rounded-md text-white" style="background: var(--brand-button); touch-action: manipulation; min-height: 44px;">
                        Continue
                    </button>
                </div>
            </div>

            {{-- Footer --}}
            <div class="px-5 py-3 shrink-0" style="border-top: 1px solid var(--border-default);">
                <button
                    @click="overdueOpen = false"
                    class="w-full py-3 rounded-md text-sm font-medium transition-colors"
                    style="background: var(--surface-2); color: var(--text-secondary); touch-action: manipulation; min-height: 48px;"
                >
                    Review Later
                </button>
            </div>
        </div>
    </div>

    {{-- ============================================================
         CREATE TASK BOTTOM SHEET
         ============================================================ --}}
    <div x-data="{ open: false, sheetTouchStartY: 0, sheetScrollTop: 0 }" x-ref="taskSheet"
         @open-create-task.window="open = true">
        @include('command-center.partials.bottom-sheet', ['title' => 'New Task'])
        @slot('slot')
            <form action="{{ route('command-center.tasks.store') }}" method="POST" class="space-y-4">
                @csrf
                <div>
                    <input
                        type="text"
                        name="title"
                        placeholder="Task title"
                        required
                        x-ref="taskTitle"
                        @focus="$el.scrollIntoView({ behavior: 'smooth', block: 'center' })"
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
                    <select
                        name="task_type"
                        class="w-full rounded-md px-4 py-3 text-sm"
                        style="background: var(--surface-2); color: var(--text-primary); border: 1px solid var(--border-default); min-height: 48px;"
                    >
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
                    <input
                        type="date"
                        name="due_date"
                        class="w-full rounded-md px-4 py-3 text-sm"
                        style="background: var(--surface-2); color: var(--text-primary); border: 1px solid var(--border-default); min-height: 48px;"
                    >
                </div>

                <div>
                    <textarea
                        name="description"
                        placeholder="Description (optional)"
                        rows="2"
                        class="w-full rounded-md px-4 py-3 text-sm resize-none"
                        style="background: var(--surface-2); color: var(--text-primary); border: 1px solid var(--border-default);"
                    ></textarea>
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

                <button
                    type="submit"
                    class="w-full py-3.5 rounded-md text-sm font-semibold text-white transition-colors"
                    style="background: var(--brand-button); min-height: 48px; touch-action: manipulation;"
                >
                    Add Task
                </button>
            </form>
        @endslot
    </div>

    {{-- ============================================================
         CREATE EVENT BOTTOM SHEET
         ============================================================ --}}
    <div x-data="{ open: false, sheetTouchStartY: 0, sheetScrollTop: 0 }" x-ref="eventSheet"
         @open-create-event.window="open = true">
        @include('command-center.partials.bottom-sheet', ['title' => 'New Event'])
        @slot('slot')
            <form action="{{ route('command-center.calendar.store') }}" method="POST" class="space-y-4">
                @csrf
                <div>
                    <input
                        type="text"
                        name="title"
                        placeholder="Event title"
                        required
                        class="w-full rounded-md px-4 py-3 text-sm"
                        style="background: var(--surface-2); color: var(--text-primary); border: 1px solid var(--border-default); min-height: 48px;"
                    >
                </div>

                <div>
                    <label class="text-xs font-medium mb-2 block" style="color: var(--text-secondary);">Date & Time</label>
                    <input
                        type="datetime-local"
                        name="event_date"
                        required
                        class="w-full rounded-md px-4 py-3 text-sm"
                        style="background: var(--surface-2); color: var(--text-primary); border: 1px solid var(--border-default); min-height: 48px;"
                    >
                </div>

                <div>
                    <label class="text-xs font-medium mb-2 block" style="color: var(--text-secondary);">End Date (optional)</label>
                    <input
                        type="datetime-local"
                        name="end_date"
                        class="w-full rounded-md px-4 py-3 text-sm"
                        style="background: var(--surface-2); color: var(--text-primary); border: 1px solid var(--border-default); min-height: 48px;"
                    >
                </div>

                <div>
                    <label class="text-xs font-medium mb-2 block" style="color: var(--text-secondary);">Type</label>
                    <select
                        name="event_type"
                        class="w-full rounded-md px-4 py-3 text-sm"
                        style="background: var(--surface-2); color: var(--text-primary); border: 1px solid var(--border-default); min-height: 48px;"
                    >
                        <option value="manual">Manual</option>
                        <option value="deal">Deal</option>
                        <option value="lease">Lease</option>
                        <option value="compliance">Compliance</option>
                        <option value="prospecting">Prospecting</option>
                    </select>
                </div>

                <div>
                    <label class="text-xs font-medium mb-2 block" style="color: var(--text-secondary);">Priority</label>
                    @include('command-center.partials.priority-pills')
                </div>

                <label class="flex items-center gap-3 py-1 cursor-pointer" style="touch-action: manipulation;">
                    <div class="relative">
                        <input type="hidden" name="all_day" value="0">
                        <input type="checkbox" name="all_day" value="1" class="sr-only peer">
                        <div class="w-11 h-6 rounded-full transition-colors duration-200 peer-checked:bg-[#0ea5e9]" style="background: var(--surface-2);"></div>
                        <div class="absolute left-0.5 top-0.5 w-5 h-5 bg-white rounded-full shadow transition-transform duration-200 peer-checked:translate-x-5"></div>
                    </div>
                    <span class="text-sm" style="color: var(--text-secondary);">All day</span>
                </label>

                <label class="flex items-center gap-3 py-1 cursor-pointer" style="touch-action: manipulation;">
                    <div class="relative">
                        <input type="hidden" name="send_reminder" value="0">
                        <input type="checkbox" name="send_reminder" value="1" checked class="sr-only peer">
                        <div class="w-11 h-6 rounded-full transition-colors duration-200 peer-checked:bg-[#0ea5e9]" style="background: var(--surface-2);"></div>
                        <div class="absolute left-0.5 top-0.5 w-5 h-5 bg-white rounded-full shadow transition-transform duration-200 peer-checked:translate-x-5"></div>
                    </div>
                    <span class="text-sm" style="color: var(--text-secondary);">Send reminder</span>
                </label>

                <div>
                    <textarea
                        name="description"
                        placeholder="Description (optional)"
                        rows="2"
                        class="w-full rounded-md px-4 py-3 text-sm resize-none"
                        style="background: var(--surface-2); color: var(--text-primary); border: 1px solid var(--border-default);"
                    ></textarea>
                </div>

                <button
                    type="submit"
                    class="w-full py-3.5 rounded-md text-sm font-semibold text-white transition-colors"
                    style="background: var(--brand-button); min-height: 48px; touch-action: manipulation;"
                >
                    Add Event
                </button>
            </form>
        @endslot
    </div>

    {{-- ============================================================
         MAIN CONTENT
         ============================================================ --}}
    <div class="px-4 py-4 md:px-6 lg:px-8 space-y-5 md:space-y-6">

        {{-- Mobile greeting --}}
        <div class="md:hidden">
            <p class="text-xs" style="color: var(--text-muted);">
                {{ now()->format('l, j F') }}
            </p>
            <h1 class="text-lg font-bold mt-0.5" style="color: var(--text-primary);">
                {{ \Illuminate\Support\Str::before($user->name, ' ') }}'s Command Center
            </h1>
        </div>

        {{-- Desktop heading --}}
        <div class="hidden md:block">
            <h1 class="text-xl font-bold" style="color: var(--text-primary);">Command Center</h1>
            <p class="text-sm mt-1" style="color: var(--text-secondary);">{{ now()->format('l, j F Y') }}</p>
        </div>

        {{-- Overdue banner (mobile) --}}
        @if($totalOverdue > 0)
            <button
                @click="overdueOpen = true"
                class="w-full md:hidden flex items-center gap-3 px-4 py-3.5 rounded-md transition-colors"
                style="background: rgba(239,68,68,0.1); border: 1px solid rgba(239,68,68,0.2); touch-action: manipulation; min-height: 48px;"
            >
                <div class="w-8 h-8 rounded-full flex items-center justify-center shrink-0" style="background: rgba(239,68,68,0.15);">
                    <span class="text-xs font-bold" style="color: #ef4444;">{{ $totalOverdue }}</span>
                </div>
                <div class="text-left">
                    <p class="text-sm font-medium" style="color: #ef4444;">Overdue items need review</p>
                    <p class="text-xs" style="color: var(--text-muted);">Tap to resolve</p>
                </div>
                <svg class="w-4 h-4 ml-auto" style="color: #ef4444;" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7"/>
                </svg>
            </button>
        @endif

        {{-- ======== a) STAT PILLS — horizontal scrollable ======== --}}
        <div class="flex gap-2.5 overflow-x-auto pb-1 -mx-4 px-4 md:mx-0 md:px-0 md:flex-wrap scrollbar-hide" style="-webkit-overflow-scrolling: touch;">
            @include('command-center.partials.stat-pill', [
                'value' => $taskSummary['today'],
                'label' => 'Today',
            ])
            @include('command-center.partials.stat-pill', [
                'value' => $taskSummary['overdue'],
                'label' => 'Overdue',
                'color' => '#ef4444',
            ])
            @include('command-center.partials.stat-pill', [
                'value' => $taskSummary['thisWeek'],
                'label' => 'This Week',
            ])
            @include('command-center.partials.stat-pill', [
                'value' => $mtdPoints . '/' . $monthlyTarget,
                'label' => 'pts',
                'color' => $mtdPoints >= $monthlyTarget ? '#22c55e' : '#f59e0b',
            ])
        </div>

        {{-- ======== Desktop 2-column layout ======== --}}
        <div class="md:grid md:grid-cols-2 md:gap-6 space-y-5 md:space-y-0">

            {{-- LEFT COLUMN --}}
            <div class="space-y-5">
                {{-- ======== b) TODAY'S AGENDA ======== --}}
                <section>
                    <div class="flex items-center justify-between mb-3">
                        <h2 class="text-sm font-semibold" style="color: var(--text-primary);">Today's Agenda</h2>
                        <span class="text-xs" style="color: var(--text-muted);">{{ $todayEvents->count() }} events</span>
                    </div>

                    @forelse($todayEvents as $event)
                        @include('command-center.partials.swipeable-card', [
                            'id' => 'event-' . $event->id,
                            'leftAction' => [
                                'label' => 'Complete',
                                'color' => '#22c55e',
                                'icon' => '<svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7"/></svg>',
                                'action' => "fetch('" . route('command-center.calendar.complete', $event->id) . "', {method:'POST',headers:{'X-CSRF-TOKEN':document.querySelector('meta[name=csrf-token]').content}}).then(()=>location.reload())",
                            ],
                        ])
                        @slot('slot')
                            <a
                                href="{{ $event->property_id ? route('corex.properties.show', $event->property_id) : '#' }}"
                                class="flex items-stretch gap-3 p-3.5"
                                style="touch-action: manipulation; min-height: 64px;"
                            >
                                {{-- Colour bar --}}
                                <div class="w-1 rounded-full shrink-0" style="background: {{ $event->colour ?? '#6b7280' }};"></div>

                                <div class="flex-1 min-w-0">
                                    <div class="flex items-center gap-2">
                                        <span class="text-xs font-medium" style="color: var(--brand-button);">
                                            @if($event->all_day)
                                                All day
                                            @else
                                                {{ \Carbon\Carbon::parse($event->event_date)->format('H:i') }}
                                            @endif
                                        </span>
                                        <span
                                            class="text-[10px] px-1.5 py-0.5 rounded"
                                            style="background: {{ $event->colour ?? '#6b7280' }}20; color: {{ $event->colour ?? '#6b7280' }};"
                                        >{{ ucfirst($event->event_type) }}</span>
                                    </div>
                                    <p class="text-sm font-medium mt-0.5 truncate" style="color: var(--text-primary);">{{ $event->title }}</p>
                                    @if($event->property)
                                        <p class="text-xs mt-0.5 truncate" style="color: var(--text-secondary);">
                                            {{ $event->property->buildDisplayAddress() }}
                                        </p>
                                    @endif
                                </div>

                                @if($event->priority === 'high' || $event->priority === 'critical')
                                    <span class="self-start text-[10px] px-1.5 py-0.5 rounded shrink-0"
                                          style="background: {{ $event->priority === 'critical' ? '#ef444420' : '#f59e0b20' }};
                                                 color: {{ $event->priority === 'critical' ? '#ef4444' : '#f59e0b' }};">
                                        {{ ucfirst($event->priority) }}
                                    </span>
                                @endif
                            </a>
                        @endslot
                    @empty
                        <div class="text-center py-10 rounded-md" style="background: var(--surface); border: 1px solid var(--border-default);">
                            <div class="w-14 h-14 mx-auto mb-3 rounded-full flex items-center justify-center" style="background: var(--surface-2);">
                                <svg class="w-7 h-7" style="color: var(--text-muted);" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                                    <path stroke-linecap="round" stroke-linejoin="round" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/>
                                </svg>
                            </div>
                            <p class="text-sm font-medium" style="color: var(--text-secondary);">No events today</p>
                            <button
                                @click="$dispatch('open-create-event')"
                                class="mt-3 text-sm font-medium px-4 py-2 rounded-md"
                                style="color: var(--brand-button); background: rgba(14,165,233,0.1); touch-action: manipulation; min-height: 44px;"
                            >+ Add Event</button>
                        </div>
                    @endforelse
                </section>

                {{-- ======== c) MY TASKS ======== --}}
                <section>
                    <div class="flex items-center justify-between mb-3">
                        <h2 class="text-sm font-semibold" style="color: var(--text-primary);">
                            My Tasks
                            <span class="font-normal text-xs ml-1" style="color: var(--text-muted);">{{ $myTasks->count() }} open</span>
                        </h2>
                        <a href="{{ route('command-center.tasks') }}" class="text-xs font-medium" style="color: var(--brand-button); touch-action: manipulation;">
                            View All &rarr;
                        </a>
                    </div>

                    @foreach($myTasks->take(5) as $task)
                        @include('command-center.partials.swipeable-card', [
                            'id' => 'task-' . $task->id,
                            'rightAction' => [
                                'label' => 'Complete',
                                'color' => '#22c55e',
                                'icon' => '<svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7"/></svg>',
                                'action' => "fetch('" . route('command-center.tasks.complete', $task->id) . "', {method:'POST',headers:{'X-CSRF-TOKEN':document.querySelector('meta[name=csrf-token]').content}}).then(()=>location.reload())",
                            ],
                            'leftAction' => [
                                'label' => 'Did Not Happen',
                                'color' => '#6b7280',
                                'icon' => '<svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636"/></svg>',
                                'action' => "fetch('" . route('command-center.resolve-task', $task->id) . "', {method:'POST',headers:{'X-CSRF-TOKEN':document.querySelector('meta[name=csrf-token]').content,'Content-Type':'application/json'},body:JSON.stringify({resolution:'did_not_happen'})}).then(()=>location.reload())",
                            ],
                        ])
                        @slot('slot')
                            <div class="flex items-center gap-3 p-3.5" style="min-height: 60px;">
                                {{-- Complete circle --}}
                                <button
                                    @click.prevent="fetch('{{ route('command-center.tasks.complete', $task->id) }}', {method:'POST',headers:{'X-CSRF-TOKEN':document.querySelector('meta[name=csrf-token]').content}}).then(()=>location.reload())"
                                    class="w-6 h-6 rounded-full shrink-0 flex items-center justify-center transition-colors"
                                    style="border: 2px solid {{ $task->isOverdue() ? '#ef4444' : 'var(--border-default)' }}; touch-action: manipulation;"
                                ></button>

                                <div class="flex-1 min-w-0">
                                    <p class="text-sm font-medium truncate" style="color: var(--text-primary);">{{ $task->title }}</p>
                                    @if($task->property)
                                        <p class="text-xs mt-0.5 truncate" style="color: var(--text-secondary);">
                                            {{ $task->property->buildDisplayAddress() }}
                                        </p>
                                    @endif
                                </div>

                                <div class="flex flex-col items-end gap-1 shrink-0">
                                    @php
                                        $prioColors = ['low' => '#6b7280', 'normal' => '#0ea5e9', 'high' => '#f59e0b', 'critical' => '#ef4444'];
                                        $pc = $prioColors[$task->priority] ?? '#6b7280';
                                    @endphp
                                    <span class="text-[10px] px-1.5 py-0.5 rounded" style="background: {{ $pc }}20; color: {{ $pc }};">
                                        {{ ucfirst($task->priority) }}
                                    </span>
                                    @if($task->due_date)
                                        <span class="text-[10px]" style="color: {{ $task->isOverdue() ? '#ef4444' : 'var(--text-muted)' }};">
                                            {{ \Carbon\Carbon::parse($task->due_date)->format('j M') }}
                                        </span>
                                    @endif
                                </div>
                            </div>
                        @endslot
                    @endforeach
                </section>

                {{-- ======== g) CANDIDATE DOCUMENTS ======== --}}
                @if($candidateDocs->count() > 0)
                    <section>
                        <h2 class="text-sm font-semibold mb-3" style="color: var(--text-primary);">
                            Documents Awaiting Authorisation
                            <span class="font-normal text-xs ml-1" style="color: var(--text-muted);">{{ $candidateDocs->count() }}</span>
                        </h2>
                        @foreach($candidateDocs as $doc)
                            <div class="rounded-md p-4 mb-2" style="background: var(--surface); border: 1px solid var(--border-default);">
                                <p class="text-sm font-medium" style="color: var(--text-primary);">{{ $doc->document->name ?? 'Document' }}</p>
                                <p class="text-xs mt-1" style="color: var(--text-secondary);">
                                    Uploaded by {{ $doc->creator->name ?? 'Unknown' }}
                                    <span class="inline-block px-1.5 py-0.5 rounded ml-1 text-[10px]"
                                          style="background: #f59e0b20; color: #f59e0b;">{{ ucfirst($doc->status) }}</span>
                                </p>
                                <a
                                    href="{{ route('corex.documents.show', $doc->document_id ?? 0) }}"
                                    class="mt-3 block w-full py-2.5 rounded-md text-center text-sm font-medium transition-colors"
                                    style="background: var(--brand-default); color: var(--brand-button); touch-action: manipulation; min-height: 44px; line-height: 24px;"
                                >
                                    Review & Authorise
                                </a>
                            </div>
                        @endforeach
                    </section>
                @endif
            </div>

            {{-- RIGHT COLUMN --}}
            <div class="space-y-5">
                {{-- ======== d) PROPERTIES NEEDING ATTENTION ======== --}}
                <section>
                    <div class="flex items-center justify-between mb-2">
                        <h2 class="text-sm font-semibold" style="color: var(--text-primary);">Properties Needing Attention</h2>
                    </div>
                    <p class="text-xs mb-3" style="color: var(--text-muted);">
                        <span style="color: #ef4444;">{{ $propHealthSummary['critical'] }} critical</span>
                        &middot;
                        <span style="color: #f59e0b;">{{ $propHealthSummary['attention'] }} attention</span>
                        &middot;
                        <span style="color: #22c55e;">{{ $propHealthSummary['good'] }} good</span>
                    </p>

                    <div class="flex gap-3 overflow-x-auto pb-2 -mx-4 px-4 md:mx-0 md:px-0 md:flex-wrap scrollbar-hide" style="-webkit-overflow-scrolling: touch;">
                        @foreach($propsNeedingAttention->take(8) as $health)
                            @php
                                $gradeColors = [
                                    'excellent' => '#22c55e',
                                    'good' => '#3b82f6',
                                    'attention' => '#f59e0b',
                                    'critical' => '#ef4444',
                                ];
                                $gc = $gradeColors[$health->grade] ?? '#6b7280';
                                $topFactor = collect($health->factors ?? [])->first();
                            @endphp
                            <a
                                href="{{ route('corex.properties.show', $health->property->id ?? 0) }}"
                                class="shrink-0 w-[200px] md:w-auto md:flex-1 md:min-w-[180px] rounded-md p-4 transition-colors"
                                style="background: var(--surface); border: 1px solid var(--border-default); touch-action: manipulation;"
                            >
                                {{-- Score circle --}}
                                <div class="flex items-center gap-3 mb-2">
                                    <div class="relative w-10 h-10 shrink-0">
                                        <svg class="w-10 h-10 -rotate-90" viewBox="0 0 36 36">
                                            <path d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                                                  fill="none" stroke="var(--surface-2)" stroke-width="3"/>
                                            <path d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                                                  fill="none" stroke="{{ $gc }}" stroke-width="3"
                                                  stroke-dasharray="{{ $health->score }}, 100"/>
                                        </svg>
                                        <span class="absolute inset-0 flex items-center justify-center text-[10px] font-bold" style="color: {{ $gc }};">{{ $health->score }}</span>
                                    </div>
                                    <span class="text-[10px] font-medium px-1.5 py-0.5 rounded" style="background: {{ $gc }}20; color: {{ $gc }};">{{ ucfirst($health->grade) }}</span>
                                </div>
                                <p class="text-xs font-medium truncate" style="color: var(--text-primary);">
                                    {{ $health->property->buildDisplayAddress() }}
                                </p>
                                @if($topFactor)
                                    <p class="text-[10px] mt-1 truncate" style="color: var(--text-muted);">
                                        {{ $topFactor['label'] ?? '' }}
                                    </p>
                                @endif
                            </a>
                        @endforeach
                    </div>
                </section>

                {{-- ======== e) SCORECARD ======== --}}
                @if($scorecard)
                    <section x-data="{ expanded: false }">
                        <button
                            @click="expanded = !expanded"
                            class="w-full flex items-center justify-between p-4 rounded-md transition-colors"
                            style="background: var(--surface); border: 1px solid var(--border-default); touch-action: manipulation; min-height: 48px;"
                        >
                            <div class="flex items-center gap-3">
                                {{-- Overall score --}}
                                <div class="relative w-10 h-10 shrink-0">
                                    @php $scColor = $scorecard->overall_score >= 80 ? '#22c55e' : ($scorecard->overall_score >= 60 ? '#f59e0b' : '#ef4444'); @endphp
                                    <svg class="w-10 h-10 -rotate-90" viewBox="0 0 36 36">
                                        <path d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                                              fill="none" stroke="var(--surface-2)" stroke-width="3"/>
                                        <path d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                                              fill="none" stroke="{{ $scColor }}" stroke-width="3"
                                              stroke-dasharray="{{ $scorecard->overall_score }}, 100"/>
                                    </svg>
                                    <span class="absolute inset-0 flex items-center justify-center text-[10px] font-bold" style="color: {{ $scColor }};">{{ $scorecard->overall_score }}</span>
                                </div>
                                <div class="text-left">
                                    <p class="text-sm font-semibold" style="color: var(--text-primary);">Agent Scorecard</p>
                                    <p class="text-xs" style="color: var(--text-muted);">Overall Performance</p>
                                </div>
                            </div>
                            <svg class="w-4 h-4 transition-transform duration-200" :class="expanded && 'rotate-180'" style="color: var(--text-muted);" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7"/>
                            </svg>
                        </button>

                        <div x-show="expanded" x-transition class="mt-2 p-4 rounded-md space-y-3" style="background: var(--surface); border: 1px solid var(--border-default);">
                            @php
                                $metrics = [
                                    ['label' => 'Tasks Completed', 'value' => ($scorecard->tasks_completed ?? 0), 'total' => ($scorecard->tasks_total ?? 1)],
                                    ['label' => 'Properties Attended', 'value' => ($scorecard->properties_attended ?? 0), 'total' => ($scorecard->properties_total ?? 1)],
                                ];
                            @endphp
                            @foreach($metrics as $m)
                                <div>
                                    <div class="flex justify-between text-xs mb-1">
                                        <span style="color: var(--text-secondary);">{{ $m['label'] }}</span>
                                        <span style="color: var(--text-primary);">{{ $m['value'] }}/{{ $m['total'] }}</span>
                                    </div>
                                    <div class="h-1.5 rounded-full" style="background: var(--surface-2);">
                                        <div class="h-full rounded-full transition-all duration-500"
                                             style="background: var(--brand-button); width: {{ $m['total'] > 0 ? min(100, round($m['value'] / $m['total'] * 100)) : 0 }}%;"></div>
                                    </div>
                                </div>
                            @endforeach
                        </div>
                    </section>
                @endif

                {{-- ======== f) MINI CALENDAR ======== --}}
                <section x-data="miniCalendar()" class="rounded-md p-4" style="background: var(--surface); border: 1px solid var(--border-default);">
                    <div class="flex items-center justify-between mb-3">
                        <h2 class="text-sm font-semibold" style="color: var(--text-primary);">
                            {{ \Carbon\Carbon::createFromFormat('Y-m', $period)->format('F Y') }}
                        </h2>
                        <a href="{{ route('command-center.calendar') }}" class="text-xs font-medium" style="color: var(--brand-button); touch-action: manipulation;">
                            Full Calendar &rarr;
                        </a>
                    </div>

                    {{-- Day headers --}}
                    <div class="grid grid-cols-7 gap-1 mb-1">
                        @foreach(['M','T','W','T','F','S','S'] as $d)
                            <div class="text-center text-[10px] py-1" style="color: var(--text-muted);">{{ $d }}</div>
                        @endforeach
                    </div>

                    {{-- Day grid --}}
                    <div class="grid grid-cols-7 gap-1">
                        @php
                            $start = \Carbon\Carbon::createFromFormat('Y-m', $period)->startOfMonth()->startOfWeek(\Carbon\Carbon::MONDAY);
                            $end = \Carbon\Carbon::createFromFormat('Y-m', $period)->endOfMonth()->endOfWeek(\Carbon\Carbon::SUNDAY);
                            $today = now()->format('Y-m-d');
                            $currentMonth = \Carbon\Carbon::createFromFormat('Y-m', $period)->month;
                        @endphp
                        @while($start->lte($end))
                            @php
                                $dateStr = $start->format('Y-m-d');
                                $isCurrentMonth = $start->month === $currentMonth;
                                $isToday = $dateStr === $today;
                                $hasEvents = isset($monthEvents[$dateStr]) && count($monthEvents[$dateStr]) > 0;
                            @endphp
                            <a
                                href="{{ route('command-center.calendar', ['date' => $dateStr, 'view' => 'agenda']) }}"
                                class="relative flex flex-col items-center justify-center rounded transition-colors"
                                style="
                                    min-height: 44px; min-width: 44px;
                                    touch-action: manipulation;
                                    {{ $isToday ? 'background: var(--brand-button); color: white;' : '' }}
                                    {{ !$isCurrentMonth ? 'opacity: 0.3;' : '' }}
                                    color: {{ $isToday ? 'white' : 'var(--text-primary)' }};
                                "
                            >
                                <span class="text-xs font-medium">{{ $start->day }}</span>
                                @if($hasEvents)
                                    <span class="absolute bottom-1.5 w-1 h-1 rounded-full" style="background: {{ $isToday ? 'white' : 'var(--brand-button)' }};"></span>
                                @endif
                            </a>
                            @php $start->addDay(); @endphp
                        @endwhile
                    </div>
                </section>
            </div>
        </div>
    </div>

    {{-- ============================================================
         FIXED BOTTOM ACTION BAR (mobile only)
         ============================================================ --}}
    <div
        class="fixed bottom-0 left-0 right-0 z-50 md:hidden"
        style="
            background: rgba(13,15,20,0.85);
            backdrop-filter: blur(20px);
            -webkit-backdrop-filter: blur(20px);
            border-top: 1px solid var(--border-default);
            padding-bottom: env(safe-area-inset-bottom, 0px);
        "
    >
        <div class="flex items-center gap-2 px-4 py-2.5">
            <button
                @click="$dispatch('open-create-task')"
                class="flex-1 flex items-center justify-center gap-2 py-3 rounded-md text-sm font-medium transition-colors"
                style="background: var(--surface-2); color: var(--text-primary); touch-action: manipulation; min-height: 48px;"
            >
                <svg class="w-4 h-4" style="color: var(--brand-icon);" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/>
                </svg>
                Task
            </button>
            <button
                @click="$dispatch('open-create-event')"
                class="flex-1 flex items-center justify-center gap-2 py-3 rounded-md text-sm font-medium transition-colors"
                style="background: var(--surface-2); color: var(--text-primary); touch-action: manipulation; min-height: 48px;"
            >
                <svg class="w-4 h-4" style="color: var(--brand-icon);" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/>
                </svg>
                Event
            </button>
            <a
                href="{{ route('corex.dashboard') }}"
                class="flex-1 flex items-center justify-center gap-2 py-3 rounded-md text-sm font-medium transition-colors"
                style="background: var(--brand-button); color: white; touch-action: manipulation; min-height: 48px;"
            >
                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M13 10V3L4 14h7v7l9-11h-7z"/>
                </svg>
                Activity
            </a>
        </div>
    </div>
</div>

{{-- ============================================================
     ALPINE JS
     ============================================================ --}}
<script>
function commandDashboard() {
    return {
        overdueOpen: false,
        currentOverdueIdx: 0,
        resolvedCount: 0,
        overdueItems: [],

        init() {
            this.buildOverdueItems();
            if (this.overdueItems.length > 0) {
                this.overdueOpen = true;
            }
        },

        buildOverdueItems() {
            const items = [];

            @foreach($overduePopupTasks ?? [] as $task)
                items.push({
                    id: {{ $task->id }},
                    type: 'task',
                    title: @json($task->title),
                    typeLabel: @json(ucfirst(str_replace('_', ' ', $task->task_type))),
                    colour: '#6b7280',
                    address: @json($task->property ? $task->property->buildDisplayAddress() : null),
                    overdueSince: @json($task->due_date ? \Carbon\Carbon::parse($task->due_date)->diffForHumans(null, true) : 'Unknown'),
                    resolveUrl: @json(route('command-center.resolve-task', $task->id)),
                    resolved: false,
                    resolution: '',
                    extendDays: 3,
                    note: '',
                    showExtend: false,
                });
            @endforeach

            @foreach($overduePopupEvents ?? [] as $event)
                items.push({
                    id: {{ $event->id }},
                    type: 'event',
                    title: @json($event->title),
                    typeLabel: @json(ucfirst($event->event_type)),
                    colour: @json($event->colour ?? '#6b7280'),
                    address: @json($event->property ? $event->property->buildDisplayAddress() : null),
                    overdueSince: @json(\Carbon\Carbon::parse($event->event_date)->diffForHumans(null, true)),
                    resolveUrl: @json(route('command-center.resolve-event', $event->id)),
                    resolved: false,
                    resolution: '',
                    extendDays: 3,
                    note: '',
                    showExtend: false,
                });
            @endforeach

            this.overdueItems = items;
        }
    };
}

function miniCalendar() {
    return {};
}
</script>

<style>
    .scrollbar-hide::-webkit-scrollbar { display: none; }
    .scrollbar-hide { -ms-overflow-style: none; scrollbar-width: none; }
</style>
@endsection
