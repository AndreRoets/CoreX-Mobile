{{--
    Swipeable Card Component
    Props:
      $id          - unique identifier
      $leftAction  - array ['label' => '', 'color' => '', 'icon' => '', 'action' => ''] (swipe left reveals right action)
      $rightAction - array ['label' => '', 'color' => '', 'icon' => '', 'action' => ''] (swipe right reveals left action)
    Content: via $slot
--}}
@props([
    'id' => uniqid('swipe-'),
    'leftAction' => null,
    'rightAction' => null,
])

<div
    x-data="{
        startX: 0,
        currentX: 0,
        offsetX: 0,
        swiping: false,
        threshold: 80,
        onTouchStart(e) {
            this.startX = e.touches[0].clientX;
            this.swiping = true;
        },
        onTouchMove(e) {
            if (!this.swiping) return;
            this.currentX = e.touches[0].clientX;
            let diff = this.currentX - this.startX;
            @if(!$rightAction) if (diff > 0) diff = 0; @endif
            @if(!$leftAction) if (diff < 0) diff = 0; @endif
            if (Math.abs(diff) > 120) diff = diff > 0 ? 120 : -120;
            this.offsetX = diff;
        },
        onTouchEnd() {
            this.swiping = false;
            if (this.offsetX < -this.threshold) {
                this.offsetX = -100;
                return;
            }
            if (this.offsetX > this.threshold) {
                this.offsetX = 100;
                return;
            }
            this.offsetX = 0;
        },
        reset() {
            this.offsetX = 0;
        }
    }"
    class="relative overflow-hidden rounded-md mb-2"
    style="touch-action: pan-y;"
>
    {{-- Left reveal (swipe right) --}}
    @if($rightAction)
        <div
            class="absolute inset-y-0 left-0 flex items-center pl-4 w-[100px]"
            style="background: {{ $rightAction['color'] ?? '#22c55e' }};"
            x-show="offsetX > 0"
        >
            <button
                @click="{{ $rightAction['action'] ?? '' }}; reset()"
                class="flex flex-col items-center gap-1 text-white text-xs font-medium w-full"
                style="touch-action: manipulation;"
            >
                @if(isset($rightAction['icon']))
                    {!! $rightAction['icon'] !!}
                @endif
                {{ $rightAction['label'] ?? 'Action' }}
            </button>
        </div>
    @endif

    {{-- Right reveal (swipe left) --}}
    @if($leftAction)
        <div
            class="absolute inset-y-0 right-0 flex items-center pr-4 w-[100px]"
            style="background: {{ $leftAction['color'] ?? '#0ea5e9' }};"
            x-show="offsetX < 0"
        >
            <button
                @click="{{ $leftAction['action'] ?? '' }}; reset()"
                class="flex flex-col items-center gap-1 text-white text-xs font-medium w-full"
                style="touch-action: manipulation;"
            >
                @if(isset($leftAction['icon']))
                    {!! $leftAction['icon'] !!}
                @endif
                {{ $leftAction['label'] ?? 'Action' }}
            </button>
        </div>
    @endif

    {{-- Main card content --}}
    <div
        class="relative transition-transform duration-200"
        :class="{ 'duration-0': swiping }"
        :style="`transform: translateX(${offsetX}px);`"
        @touchstart.passive="onTouchStart($event)"
        @touchmove.passive="onTouchMove($event)"
        @touchend="onTouchEnd()"
        @click="if (Math.abs(offsetX) > 10) { reset(); $event.preventDefault(); $event.stopPropagation(); }"
        style="background: var(--surface);"
    >
        {{ $slot }}
    </div>
</div>
