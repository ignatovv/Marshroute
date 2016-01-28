import Foundation

class TransitionContextsStackClient {
    let stack: TransitionContextsStack
    
    init(transitionContextsStack: TransitionContextsStack = TransitionContextsStack()) {
        stack = transitionContextsStack
    }
    
    func chainedTransitionsHandlerForTransitionsHandler(transitionsHandler: TransitionsHandler)
        -> TransitionsHandler?
    {
        let chainedTransition = chainedTransitionForTransitionsHandler(transitionsHandler)
        return chainedTransition?.targetTransitionsHandler
    }
    
    func transitionWith(transitionId transitionId: TransitionId, forTransitionsHandler transitionsHandler: TransitionsHandler)
        -> RestoredTransitionContext?
    {
        if let restored = stack[transitionId]
            where restored.wasPerfromedByTransitionsHandler(transitionsHandler) {
                return restored
        }
        return nil
    }
    
    func transitionsFrom(transitionId transitionId: TransitionId, forTransitionsHandler transitionsHandler: TransitionsHandler)
        -> (chainedTransition: RestoredTransitionContext?, otherTransitions: [RestoredTransitionContext]?)
    {
        return transitionsFrom(
            transitionId: transitionId,
            forTransitionsHandler: transitionsHandler,
            includingTransitionTo: false
        )
    }
    
    func transitionsTo(transitionId transitionId: TransitionId, forTransitionsHandler transitionsHandler: TransitionsHandler)
        -> (chainedTransition: RestoredTransitionContext?, otherTransitions: [RestoredTransitionContext]?)
    {
        return transitionsFrom(
            transitionId: transitionId,
            forTransitionsHandler: transitionsHandler,
            includingTransitionTo: true
        )
    }
    
}

// MARK: - heplers
private extension TransitionContextsStackClient {
    func chainedTransitionForTransitionsHandler(transitionsHandler: TransitionsHandler)
        -> RestoredTransitionContext?
    {
        if let last = lastTransitionForTransitionsHandler(transitionsHandler)
            where last.isChainedForTransitionsHandler(transitionsHandler) {
                return last
        }
        return nil
    }
    
    func lastTransitionForTransitionsHandler(transitionsHandler: TransitionsHandler)
        -> RestoredTransitionContext?
    {
        if let last = stack.last
            where last.wasPerfromedByTransitionsHandler(transitionsHandler) {
                return last
        }
        return nil
    }
    
    func transitionsFrom(
        transitionId transitionId: TransitionId,
        forTransitionsHandler transitionsHandler: TransitionsHandler,
        includingTransitionTo: Bool)
        -> (chainedTransition: RestoredTransitionContext?, otherTransitions: [RestoredTransitionContext]?)
    {
        var chainedTransition: RestoredTransitionContext? = nil
        var otherTransitions: [RestoredTransitionContext]? = nil
        
        assert(
            transitionWith(transitionId: transitionId, forTransitionsHandler: transitionsHandler) != nil,
            "проверяйте заранее, что id перехода действительно относится к обработчику переходов"
        )
        
        if let last = lastTransitionForTransitionsHandler(transitionsHandler) {
            otherTransitions = [RestoredTransitionContext]()
            
            var notChainedTransitionId: TransitionId?
            
            if last.isChainedForTransitionsHandler(transitionsHandler) {
                chainedTransition = last
                notChainedTransitionId = stack.lastPreceding(transitionId)?.transitionId
            }
            else {
                otherTransitions?.insert(last, atIndex: 0)
                notChainedTransitionId = last.transitionId
            }
            
            var didMatchId = transitionId == notChainedTransitionId
            
            while notChainedTransitionId != nil && !didMatchId {
                if let previous = stack.lastPreceding(transitionId) {
                    notChainedTransitionId = previous.transitionId

                    didMatchId = transitionId == notChainedTransitionId
                    
                    if !didMatchId || (didMatchId && includingTransitionTo) {
                        otherTransitions?.insert(previous, atIndex: 0)
                    }
                }
                else { notChainedTransitionId = nil }
            }
        }
        
        return (chainedTransition, otherTransitions)
    }
}

// MARK: - RestoredTransitionContext helpers
private extension RestoredTransitionContext {
    func wasPerfromedByTransitionsHandler(transitionsHandler: TransitionsHandler)
        -> Bool
    {
        let result = (sourceTransitionsHandler === transitionsHandler)
        return result
    }
    
    func isChainedForTransitionsHandler(transitionsHandler: TransitionsHandler)
        -> Bool
    {
        let result = (targetTransitionsHandler !== transitionsHandler)
        return result
    }
}

