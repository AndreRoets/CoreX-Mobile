@extends('layouts.corex')

@section('corex-content')
<div
    x-data="calendarApp()"
    x-init="init()"
    class="relative min-h-screen"
    style="background: var(--bg);"
>
    {{-- ============================================================
         STICKY HEADER
         ============================================================ --}}
    <div
        class="sticky top-0 z-40"
        style="
            background: rgba(5,5,5,0.9);
            backdrop-filter: blur(16px);
            -webkit-backdrop-filter: blur(16px);
            border-bottom: 1px solid var(--border-default);
        "
    >
        <div class="flex items-center justify-between px-4 py-3">
            {{-- Month navigation --}}
            <div class="flex items-center gap-3">
                <a
                    href="{{ route('command-center.calendar', ['month' => $month == 1 ? 12 : $month - 1, 'year' => $month == 1 ? $year - 1 : $year]) }}"
                    class="w-10 h-10 flex items-center justify-center rounded-md transition-colors"
                    style="background: var(--surface); color: var(--text-secondary); touch-action: manipulation;"
                >
                    <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7"/>
                    </svg>
                </a>
                <h1 class="text-base font-bold" style="color: var(--text-primary);">
                    {{ \Carbon\Carbon::create($year, $month)->format('F Y') }}
                </h1>
                <a
                    href="{{ route('command-center.calendar', ['month' => $month == 12 ? 1 : $month + 1, 'year' => $month == 12 ? $year + 1 : $year]) }}"
                    class="w-10 h-10 flex items-center justify-center rounded-md transition-colors"
                    style="background: var(--surface); color: var(--text-secondary); touch-action: manipulation;"
                >
                    <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7"/>
                    </svg>
                </a>
            </div>

            <div class="flex items-center gap-2">
                {{-- Today button --}}
                <a
                    href="{{ route('command-center.calendar', ['month' => now()->month, 'year' => now()->year]) }}"
                    class="px-3 py-2 rounded-md text-xs font-medium transition-colors"
                    style="background: var(--surface); color: var(--text-secondary); touch-action: manipulation; min-height: 40px; line-height: 24px;"
                >
                    Today
                </a>

                {{-- View toggle --}}
                <div class="flex rounded-md overflow-hidden" style="border: 1px solid var(--border-default);">
                    <a
                        href="{{ route('command-center.calendar', ['month' => $month, 'year' => $year, 'view' => 'month']) }}"
                        class="px-3 py-2 text-xs font-medium transition-colors"
                        style="
                            {{ $currentView === 'month' ? 'background: var(--brand-button); color: white;' : 'background: var(--surface); color: var(--text-secondary);' }}
                            touch-action: manipulation; min-height: 40px; line-height: 24px;
                        "
                    >Month</a>
                    <a
                        href="{{ route('command-center.calendar', ['month' => $month, 'year' => $year, 'view' => 'agenda']) }}"
                        class="px-3 py-2 text-xs font-medium transition-colors"
                        style="
                            {{ $currentView === 'agenda' ? 'background: var(--brand-button); color: white;' : 'background: var(--surface); color: var(--text-secondary);' }}
                            touch-action: manipulation; min-height: 40px; line-height: 24px;
                        "
                    >Agenda</a>
                </div>
            </div>
        </div>
    </div>

    {{-- ============================================================
         MONTH VIEW
         ============================================================ --}}
    @if($currentView === 'month')
        <div
            class="px-2 py-3 md:px-6"
            @touchstart.passive="calTouchStart($event)"
            @touchend="calTouchEnd($event)"
        >
            {{-- Day headers --}}
            <div class="grid grid-cols-7 gap-0.5 mb-1">
                @foreach(['Mon','Tue','Wed','Thu','Fri','Sat','Sun'] as $d)
                    <div class="text-center text-[10px] py-2 font-medium" style="color: var(--text-muted);">
                        <span class="md:hidden">{{ substr($d, 0, 1) }}</span>
                        <span class="hidden md:inline">{{ $d }}</span>
                    </div>
                @endforeach
            </div>

            {{-- Calendar grid --}}
            <div class="grid grid-cols-7 gap-0.5">
                @php
                    $gridStart = \Carbon\Carbon::parse($grid['start']);
                    $gridEnd = \Carbon\Carbon::parse($grid['end']);
                    $today = now()->format('Y-m-d');
                @endphp
                @while($gridStart->lte($gridEnd))
                    @php
                        $dateStr = $gridStart->format('Y-m-d');
                        $isCurrentMonth = $gridStart->month == $month;
                        $isToday = $dateStr === $today;
                        $dayEvents = $byDate[$dateStr] ?? [];
                        $evCount = count($dayEvents);
                    @endphp
                    <button
                        @click="selectedDate = '{{ $dateStr }}'; selectedEvents = {{ json_encode(collect($dayEvents)->map(fn($e) => [
                            'id' => $e->id,
                            'title' => $e->title,
                            'time' => $e->all_day ? 'All day' : \Carbon\Carbon::parse($e->event_date)->format('H:i'),
                            'type' => ucfirst($e->event_type),
                            'colour' => $e->colour ?? '#6b7280',
                            'priority' => $e->priority,
                            'property_id' => $e->property_id,
                            'address' => $e->property ? $e->property->buildDisplayAddress() : null,
                            'completeUrl' => route('command-center.calendar.complete', $e->id),
                        ])->values()) }}; daySheetOpen = true;"
                        class="relative flex flex-col items-center rounded transition-colors p-1"
                        style="
                            min-height: 52px; md:min-height: 80px;
                            touch-action: manipulation;
                            background: {{ $isToday ? 'var(--brand-default)' : 'var(--surface)' }};
                            {{ !$isCurrentMonth ? 'opacity: 0.3;' : '' }}
                        "
                    >
                        <span
                            class="text-xs font-medium w-7 h-7 flex items-center justify-center rounded-full"
                            style="{{ $isToday ? 'background: var(--brand-button); color: white;' : 'color: var(--text-primary);' }}"
                        >{{ $gridStart->day }}</span>

                        {{-- Event dots --}}
                        @if($evCount > 0)
                            <div class="flex items-center gap-0.5 mt-0.5 flex-wrap justify-center">
                                @foreach(array_slice($dayEvents, 0, 3) as $de)
                                    <span class="w-1.5 h-1.5 rounded-full" style="background: {{ $de->colour ?? '#6b7280' }};"></span>
                                @endforeach
                                @if($evCount > 3)
                                    <span class="text-[8px]" style="color: var(--text-muted);">+{{ $evCount - 3 }}</span>
                                @endif
                            </div>
                        @endif

                        {{-- Desktop: show event titles --}}
                        <div class="hidden md:block w-full mt-1 space-y-0.5">
                            @foreach(array_slice($dayEvents, 0, 2) as $de)
                                <div class="text-[9px] truncate px-1 py-0.5 rounded" style="background: {{ $de->colour ?? '#6b7280' }}15; color: {{ $de->colour ?? '#6b7280' }};">
                                    {{ $de->title }}
                                </div>
                            @endforeach
                        </div>
                    </button>
                    @php $gridStart->addDay(); @endphp
                @endwhile
            </div>
        </div>

        {{-- Day Events Bottom Sheet (mobile) --}}
        <div
            x-show="daySheetOpen"
            x-transition:enter="transition ease-out duration-300"
            x-transition:enter-start="opacity-0"
            x-transition:enter-end="opacity-100"
            x-transition:leave="transition ease-in duration-200"
            class="fixed inset-0 z-[60] flex items-end md:items-center md:justify-center"
        >
            <div class="absolute inset-0 bg-black/60" @click="daySheetOpen = false"></div>
            <div
                x-show="daySheetOpen"
                x-transition:enter="transition ease-out duration-300 transform"
                x-transition:enter-start="translate-y-full md:translate-y-0 md:scale-95 md:opacity-0"
                x-transition:enter-end="translate-y-0 md:scale-100 md:opacity-100"
                x-transition:leave="transition ease-in duration-200 transform"
                x-transition:leave-start="translate-y-0 md:scale-100 md:opacity-100"
                x-transition:leave-end="translate-y-full md:translate-y-0 md:scale-95 md:opacity-0"
                class="relative w-full md:max-w-md rounded-t-2xl md:rounded-xl overflow-hidden"
                style="background: var(--surface); max-height: 70vh; padding-bottom: env(safe-area-inset-bottom, 0px);"
            >
                {{-- Header --}}
                <div class="flex items-center justify-between px-5 py-4" style="border-bottom: 1px solid var(--border-default);">
                    <div>
                        <div class="flex justify-center mb-2 md:hidden">
                            <div class="w-10 h-1 rounded-full" style="background: var(--text-muted);"></div>
                        </div>
                        <h3 class="text-base font-semibold" style="color: var(--text-primary);"
                            x-text="selectedDate ? new Date(selectedDate + 'T00:00:00').toLocaleDateString('en-ZA', { weekday: 'long', day: 'numeric', month: 'long' }) : ''">
                        </h3>
                        <p class="text-xs mt-0.5" style="color: var(--text-muted);" x-text="`${selectedEvents.length} event${selectedEvents.length !== 1 ? 's' : ''}`"></p>
                    </div>
                    <button @click="daySheetOpen = false" class="w-8 h-8 flex items-center justify-center rounded-full" style="background: var(--surface-2); color: var(--text-secondary); touch-action: manipulation;">
                        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/></svg>
                    </button>
                </div>

                {{-- Events list --}}
                <div class="overflow-y-auto px-5 py-3" style="max-height: 50vh; -webkit-overflow-scrolling: touch;">
                    <template x-if="selectedEvents.length === 0">
                        <div class="text-center py-8">
                            <p class="text-sm" style="color: var(--text-muted);">No events</p>
                            <button
                                @click="daySheetOpen = false; $dispatch('open-create-event')"
                                class="mt-3 text-sm font-medium px-4 py-2 rounded-md"
                                style="color: var(--brand-button); background: rgba(14,165,233,0.1); touch-action: manipulation; min-height: 44px;"
                            >+ Add Event</button>
                        </div>
                    </template>
                    <template x-for="ev in selectedEvents" :key="ev.id">
                        <div class="flex items-stretch gap-3 py-3" style="border-bottom: 1px solid var(--border-default);">
                            <div class="w-1 rounded-full shrink-0" :style="`background: ${ev.colour}`"></div>
                            <div class="flex-1 min-w-0">
                                <div class="flex items-center gap-2">
                                    <span class="text-xs font-medium" style="color: var(--brand-button);" x-text="ev.time"></span>
                                    <span class="text-[10px] px-1.5 py-0.5 rounded" :style="`background: ${ev.colour}20; color: ${ev.colour};`" x-text="ev.type"></span>
                                </div>
                                <p class="text-sm font-medium mt-0.5" style="color: var(--text-primary);" x-text="ev.title"></p>
                                <a
                                    x-show="ev.address"
                                    :href="ev.property_id ? `/corex/properties/${ev.property_id}` : '#'"
                                    class="text-xs mt-0.5 block truncate"
                                    style="color: var(--text-secondary); touch-action: manipulation;"
                                    x-text="ev.address"
                                ></a>
                            </div>
                            <button
                                @click="completeEvent(ev)"
                                class="self-center w-10 h-10 flex items-center justify-center rounded-md shrink-0"
                                style="background: rgba(34,197,94,0.1); color: #22c55e; touch-action: manipulation;"
                                title="Complete"
                            >
                                <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                    <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7"/>
                                </svg>
                            </button>
                        </div>
                    </template>
                </div>
            </div>
        </div>
    @endif

    {{-- ============================================================
         AGENDA VIEW
         ============================================================ --}}
    @if($currentView === 'agenda')
        <div class="px-4 py-3 md:px-6 space-y-1" style="padding-bottom: 100px;">
            @php
                $sortedDates = collect($byDate)->sortKeys();
                $hasAnyEvents = $sortedDates->flatten()->count() > 0;
            @endphp

            @if(!$hasAnyEvents)
                <div class="text-center py-16">
                    <div class="w-16 h-16 mx-auto mb-3 rounded-full flex items-center justify-center" style="background: var(--surface);">
                        <svg class="w-8 h-8" style="color: var(--text-muted);" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/>
                        </svg>
                    </div>
                    <p class="text-sm font-medium" style="color: var(--text-secondary);">No events this month</p>
                    <button
                        @click="$dispatch('open-create-event')"
                        class="mt-3 text-sm font-medium px-4 py-2.5 rounded-md"
                        style="color: var(--brand-button); background: rgba(14,165,233,0.1); touch-action: manipulation; min-height: 44px;"
                    >+ Add Event</button>
                </div>
            @endif

            @foreach($sortedDates as $dateKey => $dayEvents)
                @if(count($dayEvents) > 0)
                    @php
                        $dateObj = \Carbon\Carbon::parse($dateKey);
                        $isToday = $dateObj->isToday();
                    @endphp
                    {{-- Date header --}}
                    <div class="sticky top-[57px] z-10 py-2" style="background: var(--bg);">
                        <div class="flex items-center gap-2">
                            @if($isToday)
                                <span class="w-2 h-2 rounded-full" style="background: var(--brand-button);"></span>
                            @endif
                            <span class="text-xs font-semibold {{ $isToday ? '' : '' }}" style="color: {{ $isToday ? 'var(--brand-button)' : 'var(--text-secondary)' }};">
                                {{ $isToday ? 'Today' : $dateObj->format('l') }} &middot; {{ $dateObj->format('j F') }}
                            </span>
                        </div>
                    </div>

                    {{-- Events --}}
                    @foreach($dayEvents as $event)
                        @include('command-center.partials.swipeable-card', [
                            'id' => 'agenda-event-' . $event->id,
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
                                class="flex items-stretch gap-3 p-4"
                                style="touch-action: manipulation; min-height: 64px;"
                            >
                                <div class="w-1 rounded-full shrink-0" style="background: {{ $event->colour ?? '#6b7280' }};"></div>
                                <div class="flex-1 min-w-0">
                                    <div class="flex items-center gap-2 flex-wrap">
                                        <span class="text-xs font-medium" style="color: var(--brand-button);">
                                            @if($event->all_day)
                                                All day
                                            @else
                                                {{ \Carbon\Carbon::parse($event->event_date)->format('H:i') }}
                                                @if($event->end_date)
                                                    - {{ \Carbon\Carbon::parse($event->end_date)->format('H:i') }}
                                                @endif
                                            @endif
                                        </span>
                                        <span class="text-[10px] px-1.5 py-0.5 rounded"
                                              style="background: {{ $event->colour ?? '#6b7280' }}20; color: {{ $event->colour ?? '#6b7280' }};">
                                            {{ ucfirst($event->event_type) }}
                                        </span>
                                        @if($event->priority === 'high' || $event->priority === 'critical')
                                            <span class="text-[10px] px-1.5 py-0.5 rounded"
                                                  style="background: {{ $event->priority === 'critical' ? '#ef444420' : '#f59e0b20' }};
                                                         color: {{ $event->priority === 'critical' ? '#ef4444' : '#f59e0b' }};">
                                                {{ ucfirst($event->priority) }}
                                            </span>
                                        @endif
                                    </div>
                                    <p class="text-sm font-medium mt-1" style="color: var(--text-primary);">{{ $event->title }}</p>
                                    @if($event->property)
                                        <p class="text-xs mt-0.5 truncate flex items-center gap-1" style="color: var(--text-secondary);">
                                            <svg class="w-3 h-3 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                                <path stroke-linecap="round" stroke-linejoin="round" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"/>
                                                <path stroke-linecap="round" stroke-linejoin="round" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"/>
                                            </svg>
                                            {{ $event->property->buildDisplayAddress() }}
                                        </p>
                                    @endif
                                </div>
                            </a>
                        @endslot
                    @endforeach
                @endif
            @endforeach
        </div>
    @endif

    {{-- ============================================================
         ADD EVENT BOTTOM SHEET
         ============================================================ --}}
    <div x-data="{ open: false, sheetTouchStartY: 0, sheetScrollTop: 0 }" @open-create-event.window="open = true">
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
                        autofocus
                        class="w-full rounded-md px-4 py-3 text-sm"
                        style="background: var(--surface-2); color: var(--text-primary); border: 1px solid var(--border-default); min-height: 48px;"
                    >
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                    <div>
                        <label class="text-xs font-medium mb-2 block" style="color: var(--text-secondary);">Start</label>
                        <input
                            type="datetime-local"
                            name="event_date"
                            required
                            class="w-full rounded-md px-4 py-3 text-sm"
                            style="background: var(--surface-2); color: var(--text-primary); border: 1px solid var(--border-default); min-height: 48px;"
                        >
                    </div>
                    <div>
                        <label class="text-xs font-medium mb-2 block" style="color: var(--text-secondary);">End (optional)</label>
                        <input
                            type="datetime-local"
                            name="end_date"
                            class="w-full rounded-md px-4 py-3 text-sm"
                            style="background: var(--surface-2); color: var(--text-primary); border: 1px solid var(--border-default); min-height: 48px;"
                        >
                    </div>
                </div>

                <div>
                    <label class="text-xs font-medium mb-2 block" style="color: var(--text-secondary);">Type</label>
                    <select name="event_type" class="w-full rounded-md px-4 py-3 text-sm" style="background: var(--surface-2); color: var(--text-primary); border: 1px solid var(--border-default); min-height: 48px;">
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

                <div class="flex items-center gap-6">
                    <label class="flex items-center gap-3 cursor-pointer" style="touch-action: manipulation;">
                        <div class="relative">
                            <input type="hidden" name="all_day" value="0">
                            <input type="checkbox" name="all_day" value="1" class="sr-only peer">
                            <div class="w-11 h-6 rounded-full transition-colors duration-200 peer-checked:bg-[#0ea5e9]" style="background: var(--surface-2);"></div>
                            <div class="absolute left-0.5 top-0.5 w-5 h-5 bg-white rounded-full shadow transition-transform duration-200 peer-checked:translate-x-5"></div>
                        </div>
                        <span class="text-sm" style="color: var(--text-secondary);">All day</span>
                    </label>

                    <label class="flex items-center gap-3 cursor-pointer" style="touch-action: manipulation;">
                        <div class="relative">
                            <input type="hidden" name="send_reminder" value="0">
                            <input type="checkbox" name="send_reminder" value="1" checked class="sr-only peer">
                            <div class="w-11 h-6 rounded-full transition-colors duration-200 peer-checked:bg-[#0ea5e9]" style="background: var(--surface-2);"></div>
                            <div class="absolute left-0.5 top-0.5 w-5 h-5 bg-white rounded-full shadow transition-transform duration-200 peer-checked:translate-x-5"></div>
                        </div>
                        <span class="text-sm" style="color: var(--text-secondary);">Reminder</span>
                    </label>
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
         MOBILE FAB (Add Event)
         ============================================================ --}}
    <button
        @click="$dispatch('open-create-event')"
        class="fixed bottom-6 right-5 z-50 w-14 h-14 rounded-full flex items-center justify-center shadow-lg shadow-sky-500/25 md:hidden transition-transform active:scale-90"
        style="background: var(--brand-button); color: white; touch-action: manipulation; padding-bottom: env(safe-area-inset-bottom, 0px);"
    >
        <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4"/>
        </svg>
    </button>
</div>

<script>
function calendarApp() {
    return {
        selectedDate: null,
        selectedEvents: [],
        daySheetOpen: false,
        calTouchStartX: 0,

        init() {},

        calTouchStart(e) {
            this.calTouchStartX = e.touches[0].clientX;
        },

        calTouchEnd(e) {
            const diff = e.changedTouches[0].clientX - this.calTouchStartX;
            if (Math.abs(diff) > 80) {
                if (diff > 0) {
                    // Swipe right = previous month
                    const prev = document.querySelector('a[href*="month={{ $month == 1 ? 12 : $month - 1 }}"]');
                    if (prev) prev.click();
                } else {
                    // Swipe left = next month
                    const next = document.querySelector('a[href*="month={{ $month == 12 ? 1 : $month + 1 }}"]');
                    if (next) next.click();
                }
            }
        },

        completeEvent(ev) {
            fetch(ev.completeUrl, {
                method: 'POST',
                headers: { 'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content }
            }).then(() => location.reload());
        }
    };
}
</script>

<style>
    .scrollbar-hide::-webkit-scrollbar { display: none; }
    .scrollbar-hide { -ms-overflow-style: none; scrollbar-width: none; }
</style>
@endsection
