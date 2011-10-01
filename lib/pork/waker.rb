require 'p_queue'

# Schedule wake up calls.
# Objects with Waker as a mixin call wake_at(time) and have their wake method
# called shortly after that time.
#
# Wake calls are made within a Fiber per EM::Synchrony.
module Pork
  module Waker
    # @next_wake is the time of the timer scheduled wake,
    # nil if there isn't one, or :immediate if the top of the queue needs to
    # happen as soon as possible

    # priorities are wake times
    # keys are Modules with wake singleton methods,
    # or [Klass, id] tuples where Klass[id] has a wake method
    @@wake_queue = PQueue.new

    # Called at server start to prime queue.
    def self.start
      Island.wake_start
      Character.wake_start

      # run through wake that are scheduled for earlier than now
      @next_wake = :immediate
      while !@@wake_queue.empty? && Time.now > @@wake_queue.top.priority
        wake
      end
      @next_wake = nil
      step
    end

    # setup a timer or next_tick for the top of the queue
    def self.step
      return if @@wake_queue.empty?

      next_wake = @@wake_queue.top.priority
      return if @next_wake == :immediate ||
        @next_wake && @next_wake < next_wake

      action = proc do
        @timer = nil
        @next_wake = nil
        wake
        step
      end

      EM.cancel_timer @timer
      @timer = nil
      wait = next_wake.until

      if wait > 0
        @next_wake = next_wake
        @timer = EM::Synchrony.add_timer wait, &action
      else
        @next_wake = :immediate
        EM.next_tick { Fiber.new(&action).resume }
      end
    end

    # Wake the top of the queue.
    # Pass the time that the wake was scheduled for.
    def self.wake
      unless @@wake_queue.empty? || @@wake_queue.top.priority > Time.now
        entry = @@wake_queue.pop
        target = if entry.key.is_a? Module
          entry.key
        else
          klass, id = entry.key
          klass[id]
        end
        target.wake entry.priority
      end
    end

    # mixin method to schedule a wake
    def wake_at time
      key = if self.is_a? Module
        self
      else
        [self.class, id]
      end
      @@wake_queue.set key, time
      Waker.step
    end

  end
end
