import XCTest

final class MasterlRouterTests: XCTestCase
{
    var transitionIdGenerator: TransitionIdGenerator!
    var transitionsCoordinator: TransitionsCoordinator!
    
    var masterAnimatingTransitionsHandlerSpy: AnimatingTransitionsHandlerSpy!
    var detailAnimatingTransitionsHandlerSpy: AnimatingTransitionsHandlerSpy!
    
    var targetViewController: UIViewController!
    
    var router: MasterRouter!
    
    override func setUp() {
        super.setUp()
        
        transitionIdGenerator = TransitionIdGeneratorImpl()
        
        transitionsCoordinator = TransitionsCoordinatorImpl(
            stackClientProvider: TransitionContextsStackClientProviderImpl()
        )
        
        masterAnimatingTransitionsHandlerSpy = AnimatingTransitionsHandlerSpy(
            transitionsCoordinator: transitionsCoordinator
        )
        
        detailAnimatingTransitionsHandlerSpy = AnimatingTransitionsHandlerSpy(
            transitionsCoordinator: transitionsCoordinator
        )
        
        targetViewController = UIViewController()
        
        router = BaseMasterDetailRouter(
            routerSeed: MasterDetailRouterSeed(
                masterTransitionsHandlerBox: .init(
                    animatingTransitionsHandler: masterAnimatingTransitionsHandlerSpy
                ),
                detailTransitionsHandlerBox: .init(
                    animatingTransitionsHandler: detailAnimatingTransitionsHandlerSpy
                ),
                transitionId: transitionIdGenerator.generateNewTransitionId(),
                presentingTransitionsHandler: nil,
                transitionsCoordinator: transitionsCoordinator,
                transitionIdGenerator: transitionIdGenerator,
                controllersProvider: RouterControllersProviderImpl()
            )
        )
    }
    
    // MARK: - Master Transitions Handler
    
    func testThatMasterDetailRouterCallsItsMasterTransitionsHandlerOn_SetMasterViewControllerDerivedFrom_WithCorrectResettingContext() {
        // Given
        var nextMasterDetailModuleRouterSeed: MasterDetailRouterSeed!
        
        // When
        router.setMasterViewControllerDerivedFrom { (routerSeed) -> UIViewController in
            nextMasterDetailModuleRouterSeed = routerSeed
            return targetViewController
        }
        
        // Then
        XCTAssert(masterAnimatingTransitionsHandlerSpy.resetWithTransitionCalled)
        
        let resettingContext = masterAnimatingTransitionsHandlerSpy.resetWithTransitionContextParameter
        XCTAssertEqual(resettingContext.transitionId, nextMasterDetailModuleRouterSeed.transitionId)
        XCTAssert(resettingContext.targetViewController === targetViewController)
        XCTAssert(resettingContext.targetTransitionsHandlerBox.unbox() === masterAnimatingTransitionsHandlerSpy)
        XCTAssertNil(resettingContext.storableParameters)
        if case .ResettingNavigationRoot(_) = resettingContext.resettingAnimationLaunchingContextBox {} else { XCTFail() }
    }
    
    func testThatMasterDetailRouterCallsItsMasterTransitionsHandlerOn_SetMasterViewControllerDerivedFrom_WithCorrectResettingContext_IfCustomAnimator() {
        // Given
        var nextMasterDetailModuleRouterSeed: MasterDetailRouterSeed!
        let resetNavigationTransitionsAnimator = ResetNavigationTransitionsAnimator()
        
        // When
        router.setMasterViewControllerDerivedFrom( { (routerSeed) -> UIViewController in
            nextMasterDetailModuleRouterSeed = routerSeed
            return targetViewController
            }, animator: resetNavigationTransitionsAnimator
        )
        
        // Then
        XCTAssert(masterAnimatingTransitionsHandlerSpy.resetWithTransitionCalled)
        
        let resettingContext = masterAnimatingTransitionsHandlerSpy.resetWithTransitionContextParameter
        XCTAssertEqual(resettingContext.transitionId, nextMasterDetailModuleRouterSeed.transitionId)
        XCTAssert(resettingContext.targetViewController === targetViewController)
        XCTAssert(resettingContext.targetTransitionsHandlerBox.unbox() === masterAnimatingTransitionsHandlerSpy)
        XCTAssertNil(resettingContext.storableParameters)
        if case .ResettingNavigationRoot(let launchingContext) = resettingContext.resettingAnimationLaunchingContextBox {
            XCTAssert(launchingContext.animator === resetNavigationTransitionsAnimator)
        } else { XCTFail() }
    }
    
    func testThatMasterDetailRouterCallsItsMasterTransitionsHandlerOn_PushMasterViewControllerDerivedFrom_WithCorrectPresentationContext() {
        // Given
        var nextMasterDetailModuleRouterSeed: MasterDetailRouterSeed!
        
        // When
        router.pushMasterViewControllerDerivedFrom { (routerSeed) -> UIViewController in
            nextMasterDetailModuleRouterSeed = routerSeed
            return targetViewController
        }
        
        // Then
        XCTAssert(masterAnimatingTransitionsHandlerSpy.performTransitionCalled)
        
        let presentationContext = masterAnimatingTransitionsHandlerSpy.perFormTransitionContextParameter
        XCTAssertEqual(presentationContext.transitionId, nextMasterDetailModuleRouterSeed.transitionId)
        XCTAssert(presentationContext.targetViewController === targetViewController)
        if case .PendingAnimating = presentationContext.targetTransitionsHandlerBox {} else { XCTFail() }
        XCTAssertNil(presentationContext.storableParameters)
        if case .Push(_) = presentationContext.presentationAnimationLaunchingContextBox {} else { XCTFail() }
    }
    
    func testThatMasterDetailRouterCallsItsMasterTransitionsHandlerOn_PushMasterViewControllerDerivedFrom_WithCorrectPresentationContext_IfCustomAnimator() {
        // Given
        var nextMasterDetailModuleRouterSeed: MasterDetailRouterSeed!
        let navigationTransitionsAnimator = NavigationTransitionsAnimator()
        
        // When
        router.pushMasterViewControllerDerivedFrom( { (routerSeed) -> UIViewController in
            nextMasterDetailModuleRouterSeed = routerSeed
            return targetViewController
            }, animator: navigationTransitionsAnimator
        )
        
        // Then
        XCTAssert(masterAnimatingTransitionsHandlerSpy.performTransitionCalled)
        
        let presentationContext = masterAnimatingTransitionsHandlerSpy.perFormTransitionContextParameter
        XCTAssertEqual(presentationContext.transitionId, nextMasterDetailModuleRouterSeed.transitionId)
        XCTAssert(presentationContext.targetViewController === targetViewController)
        if case .PendingAnimating = presentationContext.targetTransitionsHandlerBox {} else { XCTFail() }
        XCTAssertNil(presentationContext.storableParameters)
        if case .Push(let launchingContext) = presentationContext.presentationAnimationLaunchingContextBox {
            XCTAssert(launchingContext.animator === navigationTransitionsAnimator)
        } else { XCTFail() }
    }
    
    // MARK: - Detail Transitions Handler
    
    func testThatMasterDetailRouterCallsItsDetailTransitionsHandlerOn_SetDetailViewControllerDerivedFrom_WithCorrectResettingContext() {
        // Given
        var nextModuleRouterSeed: RouterSeed!
        
        // When
        router.setDetailViewControllerDerivedFrom { (routerSeed) -> UIViewController in
            nextModuleRouterSeed = routerSeed
            return targetViewController
        }
        
        // Then
        XCTAssert(detailAnimatingTransitionsHandlerSpy.resetWithTransitionCalled)
        
        let resettingContext = detailAnimatingTransitionsHandlerSpy.resetWithTransitionContextParameter
        XCTAssertEqual(resettingContext.transitionId, nextModuleRouterSeed.transitionId)
        XCTAssertEqual(resettingContext.transitionId, nextModuleRouterSeed.transitionId)
        XCTAssert(resettingContext.targetViewController === targetViewController)
        XCTAssert(resettingContext.targetTransitionsHandlerBox.unbox() === detailAnimatingTransitionsHandlerSpy)
        XCTAssertNil(resettingContext.storableParameters)
        if case .ResettingNavigationRoot(_) = resettingContext.resettingAnimationLaunchingContextBox {} else { XCTFail() }
    }
    
    func testThatMasterDetailRouterCallsItsDetailTransitionsHandlerOn_SetDetailViewControllerDerivedFrom_WithCorrectResettingContext_IfCustomAnimator() {
        // Given
        var nextModuleRouterSeed: RouterSeed!
        let resetNavigationTransitionsAnimator = ResetNavigationTransitionsAnimator()
        
        // When
        router.setDetailViewControllerDerivedFrom( { (routerSeed) -> UIViewController in
            nextModuleRouterSeed = routerSeed
            return targetViewController
            }, animator: resetNavigationTransitionsAnimator
        )
        
        // Then
        XCTAssert(detailAnimatingTransitionsHandlerSpy.resetWithTransitionCalled)
        
        let resettingContext = detailAnimatingTransitionsHandlerSpy.resetWithTransitionContextParameter
        XCTAssertEqual(resettingContext.transitionId, nextModuleRouterSeed.transitionId)
        XCTAssertEqual(resettingContext.transitionId, nextModuleRouterSeed.transitionId)
        XCTAssert(resettingContext.targetViewController === targetViewController)
        XCTAssert(resettingContext.targetTransitionsHandlerBox.unbox() === detailAnimatingTransitionsHandlerSpy)
        XCTAssertNil(resettingContext.storableParameters)
        if case .ResettingNavigationRoot(let launchingContext) = resettingContext.resettingAnimationLaunchingContextBox {
            XCTAssert(launchingContext.animator === resetNavigationTransitionsAnimator)
        } else { XCTFail() }
    }
    
    func testThatMasterDetailRouterCallsItsDetailTransitionsHandlerOn_PushDetailViewControllerDerivedFrom_WithCorrectPresentationContext() {
        // Given
        var nextModuleRouterSeed: RouterSeed!
        
        // When
        router.pushDetailViewControllerDerivedFrom { (routerSeed) -> UIViewController in
            nextModuleRouterSeed = routerSeed
            return targetViewController
        }
        
        // Then
        XCTAssert(detailAnimatingTransitionsHandlerSpy.performTransitionCalled)
        
        let presentationContext = detailAnimatingTransitionsHandlerSpy.perFormTransitionContextParameter
        XCTAssertEqual(presentationContext.transitionId, nextModuleRouterSeed.transitionId)
        XCTAssertEqual(presentationContext.transitionId, nextModuleRouterSeed.transitionId)
        XCTAssert(presentationContext.targetViewController === targetViewController)
        if case .PendingAnimating = presentationContext.targetTransitionsHandlerBox {} else { XCTFail() }
        XCTAssertNil(presentationContext.storableParameters)
        if case .Push(_) = presentationContext.presentationAnimationLaunchingContextBox {} else { XCTFail() }
    }
    
    func testThatMasterDetailRouterCallsItsDetailTransitionsHandlerOn_PushDetailViewControllerDerivedFrom_WithCorrectPresentationContext_IfCustomAnimator() {
        // Given
        var nextModuleRouterSeed: RouterSeed!
        let navigationTransitionsAnimator = NavigationTransitionsAnimator()
        
        // When
        router.pushDetailViewControllerDerivedFrom( { (routerSeed) -> UIViewController in
            nextModuleRouterSeed = routerSeed
            return targetViewController
            }, animator: navigationTransitionsAnimator
        )
        
        // Then
        XCTAssert(detailAnimatingTransitionsHandlerSpy.performTransitionCalled)
        
        let presentationContext = detailAnimatingTransitionsHandlerSpy.perFormTransitionContextParameter
        XCTAssertEqual(presentationContext.transitionId, nextModuleRouterSeed.transitionId)
        XCTAssertEqual(presentationContext.transitionId, nextModuleRouterSeed.transitionId)
        XCTAssert(presentationContext.targetViewController === targetViewController)
        if case .PendingAnimating = presentationContext.targetTransitionsHandlerBox {} else { XCTFail() }
        XCTAssertNil(presentationContext.storableParameters)
        if case .Push(let launchingContext) = presentationContext.presentationAnimationLaunchingContextBox {
            XCTAssert(launchingContext.animator === navigationTransitionsAnimator)
        } else { XCTFail() }
    }
}
