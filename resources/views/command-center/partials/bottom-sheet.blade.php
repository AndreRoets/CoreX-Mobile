{{--
    Bottom Sheet Component
    Usage: @include('command-center.partials.bottom-sheet', ['id' => 'create-task', 'title' => 'New Task'])
    Control: Alpine x-data on parent must expose `open` boolean
    Content: pass via $slot
--}}
<div
    x-show="open"
    x-transition:enter="transition ease-out duration-300"
    x-transition:enter-start="opacity-0"
    x-transition:enter-end="opacity-100"
    x-transition:leave="transition ease-in duration-200"
    x-transition:leave-start="opacity-100"
    x-transition:leave-end="opacity-0"
    class="fixed inset-0 z-[60] flex items-end justify-center"
    @keydown.escape.window="open = false"
    style="touch-action: none;"
>
    {{-- Backdrop --}}
    <div
        class="absolute inset-0 bg-black/60 backdrop-blur-sm"
        @click="open = false"
    ></div>

    {{-- Sheet --}}
    <div
        x-show="open"
        x-transition:enter="transition ease-out duration-300 transform"
        x-transition:enter-start="translate-y-full"
        x-transition:enter-end="translate-y-0"
        x-transition:leave="transition ease-in duration-200 transform"
        x-transition:leave-start="translate-y-0"
        x-transition:leave-end="translate-y-full"
        class="relative w-full max-w-lg rounded-t-2xl overflow-hidden flex flex-col"
        style="background: var(--surface); max-height: 85vh; overscroll-behavior: contain; padding-bottom: env(safe-area-inset-bottom, 0px);"
        x-ref="sheetBody"
        @touchstart.passive="
            sheetTouchStartY = $event.touches[0].clientY;
            sheetScrollTop = $refs.sheetBody.scrollTop;
        "
        @touchmove.passive="
            const dy = $event.touches[0].clientY - sheetTouchStartY;
            if (dy > 80 && sheetScrollTop <= 0) { open = false; }
        "
    >
        {{-- Drag Handle --}}
        <div class="flex justify-center pt-3 pb-1 shrink-0 cursor-grab" @click="open = false">
            <div class="w-10 h-1 rounded-full" style="background: var(--text-muted);"></div>
        </div>

        {{-- Header --}}
        @if(isset($title))
            <div class="flex items-center justify-between px-5 pb-3 shrink-0" style="border-bottom: 1px solid var(--border-default);">
                <h3 class="text-base font-semibold" style="color: var(--text-primary);">{{ $title }}</h3>
                <button
                    @click="open = false"
                    class="w-8 h-8 flex items-center justify-center rounded-full transition-colors duration-200"
                    style="background: var(--surface-2); color: var(--text-secondary); touch-action: manipulation;"
                >
                    <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
                    </svg>
                </button>
            </div>
        @endif

        {{-- Content --}}
        <div class="flex-1 overflow-y-auto px-5 py-4" style="-webkit-overflow-scrolling: touch;">
            {{ $slot }}
        </div>
    </div>
</div>
