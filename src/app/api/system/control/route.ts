import { NextResponse } from 'next/server';

export async function POST(req: Request) {
    try {
        const { port } = await req.json();
        
        // Use Edge-compatible approach - call backend kill endpoint
        const response = await fetch(`http://localhost:8001/admin/kill-port?port=${port}`, {
            method: 'POST'
        });
        
        if (response.ok) {
            return NextResponse.json({ status: "success", message: `Port ${port} killed` });
        } else {
            return NextResponse.json({ status: "error", message: "Failed to kill port" }, { status: 500 });
        }
    } catch (error) {
        return NextResponse.json({ status: "error", message: String(error) }, { status: 500 });
    }
}
