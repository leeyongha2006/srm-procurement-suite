/**
 * 구매요청부터 세금계산서까지 이어지는 구매 단계의 순서를 한곳에서 관리한다.
 *
 * 화면 버튼, 트리거, 배치가 각자 "다음 단계" 를 하드코딩하면
 * 단계 하나를 끼워 넣을 때 여러 곳을 고쳐야 한다.
 * 그래서 순서는 여기서만 정하고, 나머지는 이 클래스에 물어본다.
 */
public with sharing class ProcurementFlow {

    public enum Stage {
        PURCHASE_REQUEST,
        PURCHASE_PLAN,
        RFQ,
        CONTRACT,
        PURCHASE_ORDER,
        DELIVERY,
        RECEIPT,
        INSPECTION,
        INVOICE,
        TAX_INVOICE
    }

    public class FlowException extends Exception {}

    /**
     * @param current 현재 단계
     * @return 다음 단계, 마지막 단계면 null
     */
    public static Stage nextStage(Stage current) {
        List<Stage> stages = Stage.values();
        Integer index = current.ordinal();
        return index + 1 < stages.size() ? stages[index + 1] : null;
    }

    /**
     * 바로 다음 단계로만 진행할 수 있고, 반려는 이전 단계 어디로든 돌아갈 수 있다.
     */
    public static Boolean canMove(Stage fromStage, Stage toStage) {
        if (fromStage == null || toStage == null || fromStage == toStage) {
            return false;
        }
        if (toStage.ordinal() < fromStage.ordinal()) {
            return true;
        }
        return toStage == nextStage(fromStage);
    }

    /**
     * 여러 건을 한 번에 검사하고, 진행할 수 없는 건은 모아서 한 번에 알린다.
     *
     * @param moves 레코드 키 → [현재 단계, 바꿀 단계]
     */
    public static void validateMoves(Map<String, List<Stage>> moves) {
        List<String> invalid = new List<String>();
        for (String key : moves.keySet()) {
            List<Stage> pair = moves.get(key);
            if (!canMove(pair[0], pair[1])) {
                invalid.add(key + ' (' + pair[0] + ' → ' + pair[1] + ')');
            }
        }
        if (!invalid.isEmpty()) {
            throw new FlowException('진행할 수 없는 단계 변경: ' + String.join(invalid, ', '));
        }
    }
}
