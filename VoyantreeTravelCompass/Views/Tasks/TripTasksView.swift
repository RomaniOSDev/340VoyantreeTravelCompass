import SwiftUI

struct TripTasksView: View {
    @EnvironmentObject private var store: AppDataStore
    let destinationId: UUID
    @State private var showForm = false
    @State private var editing: TripTask?
    @State private var undoTask: TripTask?

    private var tasks: [TripTask] {
        store.tripTasks.filter { $0.destinationId == destinationId }
    }

    private var openTasks: [TripTask] { tasks.filter { !$0.completed } }
    private var doneTasks: [TripTask] { tasks.filter { $0.completed } }

    var body: some View {
        ZStack {
            Color.clear
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                Image("BannerPack")
                    .resizable()
                    .scaledToFill()
                    .ticketClip(height: 120)

                if tasks.isEmpty {
                    TicketCard {
                        VStack(spacing: 10) {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 36))
                                .foregroundColor(AppTheme.primary)
                            Text("No Tasks Yet")
                                .font(.headline)
                            Text("Add the first kit item for this walking trip.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    section("Open", items: openTasks)
                    if !doneTasks.isEmpty {
                        section("Completed Tasks", items: doneTasks)
                    }
                }

                if let undoTask {
                    Button("Undo last completion") {
                        var t = undoTask
                        t.completed = false
                        store.upsertTask(t)
                        self.undoTask = nil
                    }
                    .frame(minHeight: 44)
                }

                GoldActionButton(title: "Add task", systemImage: "plus") {
                    showForm = true
                }
            }
            .padding(18)
            }
            .clearScrollBackground()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .screenBackdrop("BgPass")
        .navigationTitle("Tasks")
        .sheet(isPresented: $showForm) {
            TaskFormView(destinationId: destinationId)
                .environmentObject(store)
        }
        .sheet(item: $editing) { task in
            TaskFormView(destinationId: destinationId, existing: task)
                .environmentObject(store)
        }
    }

    private func section(_ title: String, items: [TripTask]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            ForEach(items) { task in
                TicketCard {
                    HStack {
                        Button {
                            var copy = task
                            copy.completed.toggle()
                            store.upsertTask(copy)
                            if copy.completed { undoTask = copy }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Image(systemName: task.completed ? "checkmark.square.fill" : "square")
                                .foregroundColor(AppTheme.primary)
                                .frame(width: 44, height: 44)
                        }
                        VStack(alignment: .leading) {
                            Text(task.title)
                                .strikethrough(task.completed)
                            Text(task.category)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Edit") { editing = task }
                    }
                }
                .contextMenu {
                    Button("Edit") { editing = task }
                    Button("Delete", role: .destructive) { store.deleteTask(task.id) }
                }
            }
        }
    }
}
