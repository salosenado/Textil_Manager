//
//  SuperbaseClient.swift
//  Textil
//
//  Created by Salomon Senado on 2/9/26.
//
//  SupabaseClient.swift
//  Textil
//

import Foundation
import Supabase

let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://pamvyhtvuhhudshuvcph.supabase.co")!,
    supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBhbXZ5aHR2dWhodWRzaHV2Y3BoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA1ODI0OTUsImV4cCI6MjA4NjE1ODQ5NX0.fWDD4MQUztL-peQ4Azu6za-vP0J0Bf3tlwfY4LizVmY"
)
