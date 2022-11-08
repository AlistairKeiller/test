# implimentation of https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0247294

# Egg-laying rate
l_0 = 2000
# Days in brood class
n_B = 20
# Days in nurse class
n_N = 10
# Days in nectar-receiver class
n_R = 11
# Days in forager class
n_F = 14
# Contact rate between nurse bees and brood
k_NB = 0.1
# Contact rate between nectar-receiver and nurse bees
k_RN = 0.5
# Contact rate between foragers and nectar-receivers
k_FR = 1.44
# Duration of a storage cycle
t_s = 0.01
# Rate of nectar-collecting
k_r = 0.5
# Probability of disease transmission per contact
p_t0 = 0.3
p_t1 = 0.3
p_t2 = 0.3
# Probability of infected foragers to return home
p_surv = 0.0
# Rate of infected bee removal by healthy nurses
k_rem = 2.5e-3
# Probability of healthy nurses being infected from infected brood during performing hygienic removal
p_t,rem = 0.0
# Disease-related death rate of infected bees
k_d = 0.0

# B0 ¼ l0   B
# nB
#   pt0 � kNB � iN � B ð1Þ
# iB0 ¼   iB
# nB
# þ pt0 � kNB � iN � B   krem � iB � N   kd � iB ð2Þ
# N0 ¼ B
# nB
#   N
# nN
#   pt1 � kRN � iR1 � N   pt;rem � krem � iB � N ð3Þ
# iN0 ¼ Bi
# nB
#   iN
# nN
# þ pt1 � kRN � iR1 � N   krem � iN � N þ pt;rem � krem � iB � N   kd � iN ð4Þ
# R0
# 0 ¼ N
# nN
#   R0
# nR
#   kFR � ðF1 þ iF1Þ � R0 þ R1
# ts
# ð5Þ
# R0
# 1 ¼   R1
# nR
# þ kFR � ðF1 þ ð1   pt2Þ � iF1Þ � R0   R1
# ts
# ð6Þ
# iR0
# 0 ¼ iN
# nN
#   iR0
# nR
#   kFR � ðF1 þ iF1Þ � iR0 þ iR1
# ts
# ð7Þ
# iR0
# 1 ¼   iR1
# nR
# þ kFR � ðF1 þ iF1Þ � iR0 þ pt2 � kFR � iF1 � R0   iR1
# ts
# ð8Þ
# F0
# 0 ¼ R0
# nR
#   F0
# nF
# þ kFR � ðR0 þ iR0Þ � F1   kr � F0 ð9Þ
# F0
# 1 ¼ R1
# nR
#   F1
# nF
#   kFR � ðR0 þ iR0Þ � F1 þ kr � F0 ð10Þ
# iF0
# 0 ¼ iR0
# nR
#   iF0
# nF
# þ kFR � ðR0 þ iR0Þ � iF1   kr � iF0 ð11Þ
# iF0
# 1 ¼ iR1
# nR
#   iF1
# nF
#   kFR � ðR0 þ iR0Þ � iF1 þ psurv � kr � iF0 


# u = (B, iB, N, iN, R_0, R_1, iR_0, iR_1, F_0, F_1, iF_0, i_F1)
#     (1, 2,  3, 4,  5,   6,   7,    8,    9,   10,  11,   12)
function hive(du, u, p, t)
    B, iB, N, iN, R_0, R_1, iR_0, iR_1, F_0, F_1, iF_0, i_F1 = u
    du[1] = l_0-B/n_B-p_t0*k_NB*iN*B
    du[2] = -iB/n_B+p_t0*k_NB*iN*B-k_rem*iB*N-k_d*iB
    du[3] = B/n_B-N/n_N-p_t1*k_RN*iR_1*N-p_t,rem*k_rem*iB*N
    du[4] = B_i/n_B-iN/n_N+p_t1*k_RN*iR_1*N+k_rem*iN*N+p_t,rem*k_rem*iB*N-k_d*iN
    du[5] = N/n_N-R_0/n_R+k_FR*(F_1+iF_1)*R_0+R_1/t_s
    du[6] = -R_1/n_R+k_FR*(F_1+(1-p_t2)*iF_1)*R_0-R_1/t_s
    du[7] = iN/n_N-iR_0/n_R-k_FR*(F_1+iF_1)*iR_0+iR_1/t_s
    du[8] = -iR_1/n_R+k_FR*(F_1+iF_1)*iR_0+p_t2*k_FR*iF_1*R_0-iR_1/t_s
    du[9] = R_0/n_R-F_0/n_F+k_FR*(R_0+iR_0)*F_1+k_r*F_0
    du[10] = R_1/n_R-iF_0/n_F-k_FR*(R_0+iR_0)*F_1-k_r*iF_0
    du[11] = iR_0/n_R-iF_0/n_F+k_FR*(R_0+iR_0)*iF_1+k_r*iF_0
    du[12] = iR_1/n_R-iF_1/n_F-k_FR*(R_0+iR_0)*iF_1-p_surv*k_r*iF_0
end