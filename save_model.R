modComp = function(model1,model2,modname){
    
    llcomp = anova(model1,model2)
    df1 = llcomp$"Chi Df"[2]
    chi1 = llcomp$"Chisq"[2]
    pr1 = llcomp$"Pr(>Chisq)"[2]
    
    test1 = data.frame(c(df1,chi1,pr1))
    colnames(test1) = modname
    rownames(test1) = c("df","chi","p")
    return(test1)
}

runEffectSize = function(model, vari1) {
    R1 = r.squaredGLMM(model)[1]
    R2 = r.squaredGLMM(model)[2]
    effeSize2 = as.matrix(c(R1, R2))
    colnames(effeSize2) = vari1
    rownames(effeSize2) = c("R1","R2") 
    return(effeSize2)
}

runContrasts = function(model, contMat, vari1) {
    savesumm = summary(glht(model, contMat), test = adjusted("none"))$test 

    mtests = cbind(savesumm$coefficients, savesumm$sigma, savesumm$tstat, savesumm$pvalues)
    colnames(mtests) = c("Estimate", "Std. Error", "t value", "p-values")
    mtests2 = data.frame(mtests)
    mtests2$DV = vari1
    # relgrad = with(model@optinfo$derivs,solve(Hessian,gradient))
    # if (max(abs(relgrad)) > .001) { ##// did not converge and should be worried
    #     mtests2$converge = 0
    # } else if (max(abs(relgrad)) < .001) {
    #     mtests2$converge = 1
    # }    
    return(mtests2)
}

CIfunc = function(DV,descriptives,grouping) {
    saveCI = c()
    for (vari in DV) {
        desc.CI = filter(descriptives, traj.properties == vari & proficiency==grouping)
        meanD = desc.CI$mean[1]-desc.CI$mean[2]
        sdevD = desc.CI$sdev[1]-desc.CI$sdev[2]
        countD = desc.CI$count[1]
    
        errorCI <- qnorm(0.975)*sdevD/sqrt(countD)
        leftCI <- meanD-errorCI
        rightCI <- meanD+errorCI
        test1 = as.matrix(c(meanD, leftCI, rightCI))
        colnames(test1) = vari
        rownames(test1) = c("Mean Difference","Left CI","Right CI")
        saveCI = cbind(saveCI,test1)
    }
    return(saveCI)
}


