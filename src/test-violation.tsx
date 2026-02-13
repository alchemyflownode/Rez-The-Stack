// 🦊 TEST - Constitutional Violation
// This should trigger Guardian immediately

export function TestComponent() {
    // ARTICLE IV: No Any Types
    const process = (data: any) => {  // Should show red squiggle
        return data;
    };
    
    // ARTICLE II: No Probabilistic APIs
    const id = Math.random().toString(); // Should show warning
    
    return <div>{id}</div>;
}
