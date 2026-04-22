import { NextResponse } from 'next/server'

export async function GET() {
  return NextResponse.json([], {
    headers: {
      'Content-Type': 'application/json',
      'X-WP-Total': '0',
      'X-WP-TotalPages': '0',
      'X-Powered-By': 'WordPress/6.5.2',
    },
  })
}
