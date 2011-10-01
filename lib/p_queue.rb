# Binary heap priority queue with adjustable priorities.
class PQueue
  Entry = Struct.new :key, :priority

  def initialize
    # binary heap of Entries.
    @array = []

    # lookup array index of keys in the queue
    @table = {}
  end

  def set key, priority
    if (index = @table[key])
      old_priority = @array[index].priority
      @array[index].priority = priority
      if priority < old_priority
        bubble_up index
      elsif priority > old_priority
        bubble_down index
      end
    else
      index = @array.length
      @array.push Entry.new(key, priority)
      @table[key] = index
      bubble_up index
    end
  end

  def size
    @array.size
  end

  def empty?
    @array.empty?
  end

  # see lowest priority entry
  def top
    @array[0]
  end

  # remove lowest priority entry
  def pop
    remove 0
  end

  def delete key
    if (index = @table[key])
      remove index
    end
  end

  def each &b
    @array.each &b
  end

  def each!
    return enum_for(__method__) unless block_given?
    size.times { yield pop }
  end

  private

  # replace element at index with bottom element, then bubble that down
  def remove index
    removed = @array[index]
    if @array.length > 1
      @array[index] = @array[-1]
      @array.pop
      bubble_down index
    else
      @array = []
    end
    @table.delete(removed.key) if removed
    removed
  end

  def bubble_up index
    element = @array[index]
    while index > 0
      parent_index = (index + 1) / 2 - 1
      parent = @array[parent_index]
      break if element.priority >= parent.priority
      @array[index], @array[parent_index] = parent, element
      @table[element.key], @table[parent.key] = parent_index, index
      index = parent_index
    end
  end

  def bubble_down index
    element = @array[index]
    length  = @array.length
    loop do
      child_2 = (index + 1) * 2
      child_1 = child_2 - 1
      swap    = nil

      if child_1 < length
        if @array[child_1].priority < element.priority
          swap = child_1
        end

        if child_2 < length
          if @array[child_2].priority < @array[swap || index].priority
            swap = child_2
          end
        end
      end

      break unless swap
      child = @array[swap]
      @array[index], @array[swap] = child, element
      @table[element.key], @table[child.key] = swap, index
      index = swap
    end
  end
end
