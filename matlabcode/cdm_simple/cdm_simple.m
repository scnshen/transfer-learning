% CDM as per the formulas by the book
% stochastic gradient descent
% with random sample selection
% Simple problem modelling

clear all;
close all;
clc;
addpath('../../libsvm-3.21/matlab');

%% Dataset preparation
dataload;

indices = randperm(size(xtest,1));
sz_h = round(size(xtest,1)/2);
xtestL = xtest(indices(1:sz_h),:);
xtestU = xtest(indices(sz_h+1:end),:);
ytestL = ytest(indices(1:sz_h),:);
ytestU = ytest(indices(sz_h+1:end),:);

%% Hyper-Parameters
c = 1;
c2 = 1; % sigma squared
lam = 1;
lamr = 0.001;
eta = 0.1;

w = 0.5*ones(size(xtrain,2),1);
store(:,1) = w;

%% Mean-variance correction
% xtrain = mean_std(xtrain);
% ytrain = mean_std(ytrain);
% xtestL = mean_std(xtestL);
% xtestU = mean_std(xtestU);
% ytestL = mean_std(ytestL);
% ytestU = mean_std(ytestU);

batch_tr = round(size(xtrain,1)/20);
batch_te = round(size(xtestL,1)/20);

%%
p = 1; s_iter =1;
X = [xtrain;xtestL];
Y = [ytrain;ytestL];
ys(:,p) = Y;
svm_model = svmtrain(Y,X,'-s 4');
svm_model_base = svmtrain(ytestL,xtestL,'-s 4');
[Tpred(:,p),Taccuracy(:,p),~] = svmpredict(Y, X, svm_model);
[pred_base(:,p),accuracy_base(:,p),~] = svmpredict(ytestU, xtestU, svm_model_base);
[pred(:,p),accuracy(:,p),~] = svmpredict(ytestU, xtestU, svm_model);
loss;L(:,p) = lossv;
while p < 500
    p = p + 1;
    ynew = ytrain + xtrain*w;
    %ynew = mean_std(ynew);
    X = [xtrain;xtestL];
    Y = [ynew;ytestL];
    
    svm_model = svmtrain(Y,X,'-s 4');
    svm_model_base = svmtrain(ytestL,xtestL,'-s 4');
    [Tpred(:,p),Taccuracy(:,p),~] = svmpredict(Y, X, svm_model);
    [pred_base(:,p),accuracy_base(:,p),~] = svmpredict(ytestU, xtestU, svm_model_base);
    [pred(:,p),accuracy(:,p),~] = svmpredict(ytestU, xtestU, svm_model);
    loss;L(:,p) = lossv;
    lossv
    
    % SGD Below    
    
    indices_te = randperm(size(xtestL,1));
    xtestLs = xtestL(indices_te(1:batch_te),:);
    ytestLs = ytestL(indices_te(1:batch_te),:);
    
    indices_tr = randperm(size(xtrain,1));
    xtrains = xtrain(indices_tr(1:batch_tr),:);
    ytrains = ytrain(indices_tr(1:batch_tr),:);
    
    ynews = ynew(indices_tr(1:batch_tr),:);
    
    Ltr = kernel(xtrains,xtrains,c,c2);
    Ltr2 = inv(Ltr+lam*eye(size(xtrains,1)));
    Lte = kernel(xtestLs,xtestLs,c,c2);
    Ltetr = kernel(xtestLs,xtrains,c,c2);
    Lte2 = inv(Lte+lam*eye(size(xtestLs,1)));
    
    %%%% Updating w and b
    for k = 1:size(w,1)
        
        L_sgd(:,p) = trace(Ltr2*kernel(ynews,ynews,c,c2)*Ltr2*Ltr) - 2*trace(Ltr2*kernel(ynews,ytestLs,c,c2)*Lte2*kernel(xtestLs,xtrains,c,c2));
        s_iter = s_iter+1;
        
        % first expression
        for i = 1:size(ynews,1)
            for j = 1:size(ynews,1)
                %d_w(i,j) = (-1/c2)*(ynews(i) - ynews(j))*(I(i,k) - I(j,k));
                % Changing I over here
                d_w(i,j) = (-1/c2)*(ynews(i) - ynews(j))*(xtrain(i,k) - xtrain(j,k));
            end
        end
        dl_dk = Ltr2*Ltr'*Ltr2;
        w(k) = w(k)+ eta*trace(dl_dk'*[kernel(ynews,ynews,c,c2).*(d_w)]);
        
        % Second expression
        for i = 1:size(ynews,1)
            for j = 1:size(ytestLs,1)
                % ep_w(i,j) = (-1/c2)*(ynews(i) - ytestLs(j))*I(i,k);
                % Changing the I function
                ep_w(i,j) = (-1/c2)*(ynews(i) - ytestLs(j))*xtrain(i,k);
            end
        end
        dl_dk2 = 2*Ltr2*Ltetr'*Lte2;
        w(k) = w(k) + eta*trace(dl_dk2'*[kernel(ynews,ytestLs,c,c2).*ep_w]);
    end
    w = w + lamr*2*w;

    storew(:,p) = w;
    w
        
end
figure(1);
subplot(3,1,1);
plot(L(2,1:end),'-*');
subplot(3,1,2);
plot(Taccuracy(2,1:end),'-*');
subplot(3,1,3);
plot(accuracy(2,1:end),'-*');