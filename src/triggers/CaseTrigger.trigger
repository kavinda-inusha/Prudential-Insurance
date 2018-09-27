trigger CaseTrigger on Case (before insert, before update, after update) {
    Group mcGroup = [ SELECT Id, Type FROM Group WHERE Type = 'Queue' AND Name = 'Case MC Queue' ];
    Set<Id> caseIds = new Set<Id>();
    
    if (Trigger.isBefore) { 
        if (Trigger.isInsert) {
            // Default's the Entitlement 
            Entitlement mcEntitlement = [ SELECT Id FROM Entitlement WHERE Name = 'Standard CMU Email Support' ];       
        
            for (Case newCase : Trigger.new) {
                if (newCase.ownerId == mcGroup.Id) {
                    newCase.EntitlementId = mcEntitlement.Id;
                    newCase.status = 'Pending MC’s assessment';
                }
            }
        } else {
            // Update's Case Milestone
            caseIds = new Set<Id>();
        
            // Once IO Assigned, move to 'New' stats
            for (Case newCase : Trigger.new) {
                if (newCase.ownerId != Trigger.oldMap.get(newCase.Id).ownerId) {
                    newCase.status = 'New';                         
                    caseIds.add(newCase.Id);    
                }        
            }
            
             List<CaseMilestone> cmsToUpdate = [SELECT Id, completionDate
                                            FROM CaseMilestone cm
                                            WHERE caseId in :caseIds and cm.MilestoneType.Name= 'Verify Complaint'
                                            AND completionDate = null ];
            if (cmsToUpdate.isEmpty() == false){
                for (CaseMilestone cm : cmsToUpdate){
                    cm.completionDate = Date.today();
                }
                update cmsToUpdate;
            }
        }
    } else {
        // Update's Case Milestone
        caseIds = new Set<Id>();
        
        for (Case newCase : Trigger.new) {
            if (newCase.status != Trigger.oldMap.get(newCase.Id).status && newCase.status == 'Complaint Interview Setup') {
                caseIds.add(newCase.Id);              
            }
        }
        
         List<CaseMilestone> cmsToUpdate = [SELECT Id, completionDate
                                            FROM CaseMilestone cm
                                            WHERE caseId in :caseIds and cm.MilestoneType.Name= 'Do preparation work'
                                            AND completionDate = null ];
        if (cmsToUpdate.isEmpty() == false){
            for (CaseMilestone cm : cmsToUpdate){
                cm.completionDate = Date.today();
            }
            update cmsToUpdate;
        }
    }
}