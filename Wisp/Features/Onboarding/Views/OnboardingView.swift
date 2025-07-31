import SwiftUI

//struct OnboardingView: View {
//    @State private var currentPage = 0
//    @State private var showMainApp = false
//    private let logger = Logger.ui
//    
//    private let pages = OnboardingPage.allPages
//    
//    var body: some View {
//        GeometryReader { geometry in
//            ZStack {
//                // Enhanced dark gradient background
//                LinearGradient(
//                    colors: [
//                        Color.black,
//                        Color(red: 0.02, green: 0.02, blue: 0.08),
//                        Color(red: 0.05, green: 0.05, blue: 0.15),
//                        Color(red: 0.08, green: 0.05, blue: 0.12)
//                    ],
//                    startPoint: .topLeading,
//                    endPoint: .bottomTrailing
//                )
//                .ignoresSafeArea()
//                
//                VStack(spacing: 0) {
//                    // Page Content
//                    TabView(selection: $currentPage) {
//                        ForEach(pages.indices, id: \.self) { index in
//                            pageView(for: pages[index], geometry: geometry)
//                                .tag(index)
//                        }
//                    }
//                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
//                    .animation(.easeInOut(duration: 0.5), value: currentPage)
//                    
//                    // Page Indicators and Navigation
//                    VStack(spacing: 24) {
//                        // Page Indicators
//                        HStack(spacing: 12) {
//                            ForEach(pages.indices, id: \.self) { index in
//                                Capsule()
//                                    .fill(index == currentPage ? Color.orange : Color.white.opacity(0.3))
//                                    .frame(width: index == currentPage ? 24 : 8, height: 8)
//                                    .scaleEffect(index == currentPage ? 1.0 : 0.8)
//                                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentPage)
//                            }
//                        }
//                        
//                        // Navigation Buttons
//                        HStack {
//                            if currentPage > 0 {
//                                Button("Back") {
//                                    withAnimation(.easeInOut(duration: 0.3)) {
//                                        currentPage -= 1
//                                    }
//                                }
//                                .font(.system(size: 16, weight: .medium))
//                                .foregroundColor(.white.opacity(0.7))
//                                .padding(.horizontal, 16)
//                                .padding(.vertical, 8)
//                                .background(
//                                    RoundedRectangle(cornerRadius: 8)
//                                        .fill(Color.white.opacity(0.1))
//                                )
//                            }
//                            
//                            Spacer()
//                            
//                            if currentPage < pages.count - 1 {
//                                Button("Next") {
//                                    withAnimation(.easeInOut(duration: 0.3)) {
//                                        currentPage += 1
//                                    }
//                                }
//                                .font(.system(size: 16, weight: .semibold))
//                                .foregroundColor(.white)
//                                .padding(.horizontal, 20)
//                                .padding(.vertical, 10)
//                                .background(
//                                    LinearGradient(
//                                        colors: [Color.orange, Color.orange.opacity(0.8)],
//                                        startPoint: .leading,
//                                        endPoint: .trailing
//                                    )
//                                )
//                                .cornerRadius(10)
//                            }
//                        }
//                        .padding(.horizontal, 32)
//                    }
//                    .padding(.bottom, 50)
//                }
//            }
//        }
//        .fullScreenCover(isPresented: $showMainApp) {
//            MainTabView()
//        }
//        .onAppear {
//            logger.info("Onboarding view appeared")
//        }
//    }
//    
//    @ViewBuilder
//    private func pageView(for page: OnboardingPage, geometry: GeometryProxy) -> some View {
//        switch page {
//        case .welcome:
//            WelcomePageView(onGetStarted: handleGetStarted)
//        case .ghosts:
//            GhostsPageView()
//        case .pacing:
//            PacingPageView()
//        case .insights:
//            InsightsPageView()
//        case .callToAction:
//            CallToActionPageView(
//                onGetStarted: handleGetStarted,
//                onLogIn: handleLogIn,
//                onLearnMore: handleLearnMore
//            )
//        }
//    }
//    
//    private func handleGetStarted() {
//        logger.info("User tapped Get Started")
//        // Mark onboarding as completed in UserDefaults
//        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
//        showMainApp = true
//    }
//    
//    private func handleLogIn() {
//        logger.info("User tapped Log In")
//        // Handle login flow here
//        handleGetStarted() // For now, same as get started
//    }
//    
//    private func handleLearnMore() {
//        logger.info("User tapped Learn More")
//        // Could open a web view or show more info2
//    }
//}

//enum OnboardingPage: CaseIterable {
//    case welcome
//    case ghosts
//    case pacing
//    case insights
//    case callToAction
//    
//    static var allPages: [OnboardingPage] {
//        return OnboardingPage.allCases
//    }
//}
//

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var showingAuthFlow = false
    @State private var selectedAuthFlow: AuthenticationFlow?
    
    private let pages = OnboardingPage.pages
    private let logger = LoggerAuth.shared
    
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                    OnboardingPageView(
                        page: page,
                        isLastPage: index == pages.count - 1,
                        onAuthFlowSelected: { flow in
                            logger.logUIEvent("Auth flow selected", view: "OnboardingView", details: [
                                "flow": flow.rawValue,
                                "currentPage": currentPage
                            ])
                            selectedAuthFlow = flow
                            showingAuthFlow = true
                        }
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            .onChange(of: currentPage) { oldValue, newValue in
                logger.logUIEvent("Onboarding page changed", view: "OnboardingView", details: [
                    "fromPage": oldValue,
                    "toPage": newValue,
                    "pageTitle": pages[safe: newValue]?.title ?? "unknown"
                ])
            }
        }
        .sheet(isPresented: $showingAuthFlow) {
            if let authFlow = selectedAuthFlow {
                AuthenticationFlowView(flow: authFlow)
            }
        }
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    let isLastPage: Bool
    let onAuthFlowSelected: (AuthenticationFlow) -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 20) {
                Image(systemName: page.imageName)
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)
                
                VStack(spacing: 12) {
                    Text(page.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text(page.subtitle)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Text(page.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .lineLimit(nil)
            }
            
            Spacer()
            
            if isLastPage {
                authenticationButtons
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 50)
    }
    
    private var authenticationButtons: some View {
        VStack(spacing: 16) {
            Button(action: {
                onAuthFlowSelected(.signUp)
            }) {
                Text("Create an account")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            Button(action: {
                onAuthFlowSelected(.signIn)
            }) {
                Text("Log In")
                    .font(.headline)
                    .foregroundStyle(.blue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.blue, lineWidth: 2)
                    )
            }
            
            HStack {
                Rectangle()
                    .fill(.gray.opacity(0.3))
                    .frame(height: 1)
                
                Text("or")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                
                Rectangle()
                    .fill(.gray.opacity(0.3))
                    .frame(height: 1)
            }
            .padding(.vertical, 8)
            
            Button(action: {
                onAuthFlowSelected(.googleOAuth)
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "globe")
                        .font(.title3)
                    
                    Text("Continue with Google")
                        .font(.headline)
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.gray.opacity(0.3), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    OnboardingView()
}
