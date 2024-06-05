# Unit tests for the Pearlmit

## 1. `permitBatchApprove` : External function
- **Scenario 1 :** Approves 2 types of tokens (ERC721, ERC1155) for Bob and Carol. ✅ *(This scenario covers the main functional aspects of the function)*
- **Note :** All other failure scenarios are explored through internal functions.

## 2. `clearAllowance` : External function
- **Scenario 1 :** Called by the approved operator and clears allowance.✅ 
- **Scenario 2 :** Called by a wrong operator.✅ 
- **NOTE** The permission's provider cannot clear the allowance. 

## 3. `_checkPermitBatchApproval` : Internal function
- **Scenario 1 :** The permit is approved, tested through the function `permitBatchApprove`. ✅ 
- **Scenario 2 :** Reverts due to wrong hashed data. ✅

## 4. `_checkBatchPermitData` : Internal function
- **Scenario 1 :** Permit batch transfer data is valid, no revert. Tested through the function permitBatchApprove ✅ 
- **Scenario 2 :** Reverts due to an invalid permit. ✅
- **Scenario 3 :** Reverts due to an expired permit. ✅
- **Scenario 4 :** Reverts due to the wrong nonce. ✅
