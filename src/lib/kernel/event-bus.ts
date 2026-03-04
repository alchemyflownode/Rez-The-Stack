// src/lib/kernel/event-bus.ts
type EventCallback = (...args: any[]) => void;

export class EventBus {
  private events: Map<string, EventCallback[]> = new Map();

  on(event: string, callback: EventCallback) {
    if (!this.events.has(event)) {
      this.events.set(event, []);
    }
    this.events.get(event)!.push(callback);
  }

  off(event: string, callback: EventCallback) {
    if (!this.events.has(event)) return;
    const callbacks = this.events.get(event)!.filter(cb => cb !== callback);
    if (callbacks.length === 0) {
      this.events.delete(event);
    } else {
      this.events.set(event, callbacks);
    }
  }

  emit(event: string, ...args: any[]) {
    if (!this.events.has(event)) return;
    this.events.get(event)!.forEach(cb => cb(...args));
  }

  clear() {
    this.events.clear();
  }
}

export const globalEventBus = new EventBus();
