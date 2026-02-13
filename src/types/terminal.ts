// Terminal ref interface for neural link
export interface TerminalRef {
  executeCommand: (cmd: string) => void;
}
