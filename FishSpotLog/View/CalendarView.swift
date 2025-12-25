import SwiftUI

struct CalendarView: View {
    let spots: [Spot]
    
    var fishingDays: [Date: [Spot]] {
        Dictionary(grouping: spots, by: { Calendar.current.startOfDay(for: $0.date) })
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [.darkBackground, .futuristicBlue.opacity(0.4)]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                List {
                    ForEach(fishingDays.keys.sorted(), id: \.self) { day in
                        Section(header: Text(day.formatted(date: .long, time: .omitted))
                            .foregroundColor(.futuristicCyan)) {
                            ForEach(fishingDays[day] ?? [], id: \.id) { spot in
                                Text(spot.name)
                                    .foregroundColor(.accentWhite)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .navigationTitle("Calendar")
            }
        }
        .preferredColorScheme(.dark)
    }
}

// Fish by Spot View
struct FishBySpotView: View {
    let spots: [Spot]
    
    var fishStats: [String: (count: Int, spots: [String])] {
        var stats: [String: (count: Int, spots: [String])] = [:]
        for spot in spots {
            for fish in spot.fishCaught {
                var current = stats[fish] ?? (0, [])
                current.count += 1
                current.spots.append(spot.name)
                stats[fish] = current
            }
        }
        return stats
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [.darkBackground, .neonYellow.opacity(0.3)]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                List {
                    ForEach(fishStats.keys.sorted(), id: \.self) { fish in
                        VStack(alignment: .leading) {
                            Text(fish)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(Color.accentWhite)
                            Text("Count: \(fishStats[fish]?.count ?? 0)")
                                .foregroundColor(Color.accentWhite.opacity(0.7))
                            Text("Spots: \(fishStats[fish]?.spots.joined(separator: ", ") ?? "")")
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(Color.accentWhite.opacity(0.6))
                        }
                        .padding()
                        .background(Color.darkBackground.opacity(0.7))
                        .cornerRadius(20)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .navigationTitle("Fish by Spot")
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct CheckPermissionsView: View {
    let onAllow: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            
            ZStack {
                Image("push_bg")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .ignoresSafeArea()
                
                if isLandscape {
                    VStack {
                        Spacer()
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Allow notifications about bonuses and promos".uppercased())
                                    .font(.custom("Inter-Regular_Black", size: 24))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                
                                Text("Stay tuned with best offers from our casino")
                                    .font(.custom("Inter-Regular_Bold", size: 18))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            VStack {
                                Button(action: onAllow) {
                                    Image("push_accept")
                                        .resizable()
                                        .frame(height: 60)
                                }
                                .frame(width: 350)
                                
                                Button(action: onSkip) {
                                    Image("skip_btn")
                                        .resizable()
                                        .frame(height: 40)
                                }
                                .frame(width: 320)
                            }
                        }
                        .padding(.bottom, 24)
                        .padding(.horizontal, 62)
                    }
                } else {
                    VStack(spacing: isLandscape ? 5 : 10) {
                        Spacer()
                        
                        Text("Allow notifications about bonuses and promos".uppercased())
                            .font(.custom("Inter-Regular_Black", size: 20))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Stay tuned with best offers from our casino")
                            .font(.custom("Inter-Regular_Bold", size: 15))
                            .foregroundColor(.white)
                            .padding(.horizontal, 52)
                            .multilineTextAlignment(.center)
                        
                        Button(action: onAllow) {
                            Image("push_accept")
                                .resizable()
                                .frame(height: 60)
                        }
                        .frame(width: 350)
                        .padding(.top, 12)
                        
                        Button(action: onSkip) {
                            Image("skip_btn")
                                .resizable()
                                .frame(height: 40)
                        }
                        .frame(width: 320)
                        
                        Spacer()
                            .frame(height: isLandscape ? 30 : 50)
                    }
                    .padding(.horizontal, isLandscape ? 20 : 0)
                }
                
            }
        }
        .ignoresSafeArea()
    }
}
