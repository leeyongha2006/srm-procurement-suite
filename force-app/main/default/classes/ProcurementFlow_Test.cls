@IsTest
private class ProcurementFlow_Test {

    @IsTest
    static void movesOnlyToTheNextStage() {
        Assert.isTrue(ProcurementFlow.canMove(ProcurementFlow.Stage.RFQ, ProcurementFlow.Stage.CONTRACT));
        // 계약을 건너뛰고 발주로 갈 수 없다.
        Assert.isFalse(ProcurementFlow.canMove(ProcurementFlow.Stage.RFQ, ProcurementFlow.Stage.PURCHASE_ORDER));
    }

    @IsTest
    static void allowsReturningToAnyEarlierStage() {
        Assert.isTrue(ProcurementFlow.canMove(ProcurementFlow.Stage.INSPECTION, ProcurementFlow.Stage.DELIVERY));
        Assert.isTrue(ProcurementFlow.canMove(ProcurementFlow.Stage.INVOICE, ProcurementFlow.Stage.PURCHASE_REQUEST));
    }

    @IsTest
    static void rejectsSameStageAndNull() {
        Assert.isFalse(ProcurementFlow.canMove(ProcurementFlow.Stage.RFQ, ProcurementFlow.Stage.RFQ));
        Assert.isFalse(ProcurementFlow.canMove(null, ProcurementFlow.Stage.RFQ));
    }

    @IsTest
    static void lastStageHasNoNext() {
        Assert.isNull(ProcurementFlow.nextStage(ProcurementFlow.Stage.TAX_INVOICE));
        Assert.areEqual(ProcurementFlow.Stage.RECEIPT, ProcurementFlow.nextStage(ProcurementFlow.Stage.DELIVERY));
    }

    @IsTest
    static void reportsEveryInvalidMoveAtOnce() {
        Map<String, List<ProcurementFlow.Stage>> moves = new Map<String, List<ProcurementFlow.Stage>>{
            'PO-1' => new List<ProcurementFlow.Stage>{ ProcurementFlow.Stage.PURCHASE_ORDER, ProcurementFlow.Stage.DELIVERY },
            'PO-2' => new List<ProcurementFlow.Stage>{ ProcurementFlow.Stage.PURCHASE_ORDER, ProcurementFlow.Stage.INVOICE },
            'PO-3' => new List<ProcurementFlow.Stage>{ ProcurementFlow.Stage.RFQ, ProcurementFlow.Stage.TAX_INVOICE }
        };
        try {
            ProcurementFlow.validateMoves(moves);
            Assert.fail('예외가 나야 한다');
        } catch (ProcurementFlow.FlowException e) {
            Assert.isTrue(e.getMessage().contains('PO-2'));
            Assert.isTrue(e.getMessage().contains('PO-3'));
            Assert.isFalse(e.getMessage().contains('PO-1'));
        }
    }

    @IsTest
    static void validatesBulkMoves() {
        Map<String, List<ProcurementFlow.Stage>> moves = new Map<String, List<ProcurementFlow.Stage>>();
        for (Integer i = 0; i < 200; i++) {
            moves.put('PR-' + i, new List<ProcurementFlow.Stage>{ ProcurementFlow.Stage.PURCHASE_REQUEST, ProcurementFlow.Stage.PURCHASE_PLAN });
        }
        ProcurementFlow.validateMoves(moves);
        Assert.areEqual(200, moves.size());
    }
}
