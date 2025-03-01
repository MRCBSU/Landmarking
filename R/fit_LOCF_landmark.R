#' Find the risk set for a landmark model (LOCF)
#'
#' This function is a helper function for `fit_LOCF_landmark`.
#'
#' @param data_long Data frame in long format i.e. there may be more than one row per individual
#' @template x_L
#' @template x_hor
#' @template covariates
#' @template covariates_time
#' @template individual_id
#' @template event_time
#' @template event_status
#' @return List with elements corresponding to each landmark time in x_L. Each element is a data frame, containing only those individuals
#' in the risk set at each of the landmark times x_L.
#'
#'
#' @author Isobel Barrott \email{isobel.barrott@@gmail.com}
#' @details This function finds the risk set for each of landmark times in x_L. This means that each of the individuals has a LOCF value for all covariates at the landmark time and
#' has not experienced an event up to (and including) the landmark time.
#' @export

find_LOCF_risk_set <- function(data_long,
                                  x_L,
                               x_hor,
                                  covariates,
                                  covariates_time,
                                  individual_id,
                               event_time,
                               event_status){
  if (!(is.data.frame(data_long) ||
        is.list(data_long))) {
    stop("data_long should be a list or data.frame")
  }
  if (is.data.frame(data_long)) {
    data_long <- lapply(x_L, function(x_l) {
      data_long
    })
    names(data_long) <- x_L
  }
  if (is.list(data_long)) {
    if (!setequal(names(data_long), x_L)) {
      stop("Names of elements in data_long should be landmark ages x_L")
    }
  }


  if (!(inherits(covariates,"character"))) {
    stop("covariates should have class character")
  }
  if (!(inherits(covariates_time,"character"))) {
    stop("covariates_time should have class character")
  }
  if (!(inherits(individual_id,"character"))) {
    stop("individual_id should have class character")
  }
  if (!(inherits(event_time,"character"))) {
    stop("event_time should have class character")
  }
  if (!(inherits(event_status,"character"))) {
    stop("event_status should have class character")
  }

  if (!(inherits(x_L,"numeric"))) {
     stop("'x_L' should be numeric")
  }
  if (!(inherits(x_hor,"numeric"))) {
     stop("'x_hor' should be numeric")
  }

  if (!(length(covariates_time) %in% c(length(covariates), 1))) {
    stop("Length of covariates_time should be equal to length of covariates or 1")
  }

  if (length(covariates_time) == 1) {
    covariates_time <- rep(covariates_time, times = length(covariates))
  }

  data_long_x_L <- lapply(1:length(x_L), function(i) {

    x_l <- x_L[i]
    x_h <- x_hor[i]

    data_long_x_l <- data_long[[as.character(x_l)]]
    for (col in c(covariates,
                  covariates_time,
                  individual_id,
                  event_time,
                  event_status)) {
      if (!(col %in% names(data_long_x_l))) {
        stop(col, " is not a column name in data_long")
      }
      # if(any(is.na(data_long_x_l[[col]]))){
      #   stop(col, " contains NA values")
      # }
    }

    data_long_x_l[[individual_id]] <-
      as.factor(data_long_x_l[[individual_id]])

    #Pull out individuals in the risk set
    data_long_x_l_risk_set <-
      return_ids_with_LOCF(
        data_long = data_long_x_l,
        individual_id = individual_id,
        x_L = x_l,
        covariates = covariates,
        covariates_time = covariates_time
      )
    data_long_x_l_risk_set <-
      data_long_x_l_risk_set[data_long_x_l_risk_set[[event_time]] > x_l,]
    n <-
      length(unique(data_long_x_l[[individual_id]])) - length(unique(data_long_x_l_risk_set[[individual_id]]))

    if (n >= 1) {
      warning(
        n,
        " individuals have been removed from the model building as they are not in the risk set at landmark age ",
        x_l
      )
    }
    data_long_x_l <- data_long_x_l_risk_set

    return(data_long_x_l)
  })
  names(data_long_x_L)<-x_L
  data_long_x_L
}

#' Find the last observation carried forward (LOCF) values for covariates in a dataset
#'
#' This function is a helper function for `fit_LOCF_landmark`.
#'
#' @param data_long Data frame in long format i.e. there may be more than one row per individual
#' @template x_L
#' @template covariates
#' @template covariates_time
#' @param cv_name Character string specifying the column name in `data_long` that indicates cross-validation fold
#' @template individual_id
#' @return List containing `data_longitudinal`, `model_longitudinal`, and `call`.
#'
#' `data_longitudinal` has one row for each individual in `data_long` and
#' contains the LOCF value of `covariates` at the landmark time `x_L`.
#'
#' `model_longitudinal` indicates that the LOCF approach is used.
#'
#' `call` contains the call of the function.
#'
#' @author Isobel Barrott \email{isobel.barrott@@gmail.com}
#' @details This function extracts the LOCF value for each of the `covariates` in `data_long` up to (and including) time `x_L`.
#' @export

fit_LOCF_longitudinal <- function(data_long,
                                  x_L,
                                  covariates,
                                  covariates_time,
                                  cv_name = NA,
                                  individual_id) {
  call <- match.call()
  if (!(inherits(data_long,"data.frame"))) {
    stop("data_long should be a data frame")
  }
  if (!(inherits(x_L,"numeric"))) {
    stop("'x_L' should be numeric")
  }

  for (col in c(covariates,
                covariates_time,
                individual_id)) {
    if (!(col %in% names(data_long))) {
      stop(col, " is not a column name in data_long")
    }
    # if (any(is.na(data_long[[col]]))){
    #   stop(col, " contains NA values")
    # }
  }

  if (!is.na(cv_name)) {
    if (!(cv_name %in% names(data_long))) {
      stop(cv_name, " is not a column name in data_long")
    }
    if (any(is.na(data_long[[cv_name]]))) {
      stop("The column ", cv_name, " contains NA values")
    }
  }

  if (!(length(covariates_time) %in% c(length(covariates), 1))) {
    stop("Length of covariates_time should be equal to length of covariates or 1")
  }

  if (length(covariates_time) == 1) {
    covariates_time <- rep(covariates_time, times = length(covariates))
  }

  if (dim(
    return_ids_with_LOCF(
      data_long = data_long,
      individual_id = individual_id,
      x_L = x_L,
      covariates = covariates,
      covariates_time = covariates_time
    )
  )[1] != dim(data_long)[1]) {
    stop(
      paste0(
        "data_long contains individuals that do not have a LOCF for all covariates at landmark age ",
        x_L,
        ".
                  Use function return_ids_with_LOCF to remove these individuals from the dataset data_long."
      )
    )
  }

  data_long[[individual_id]] <-
    as.factor(data_long[[individual_id]])
  data_LOCF <- data_long

  #Pick out LOCF for each covariate
  LOCF_values_by_variable <-
    lapply(1:length(covariates), function(x) {
      return_LOCF_by_variable(
        data_long = data_LOCF,
        i = x,
        covariates = covariates,
        covariates_time = covariates_time,
        individual_id = individual_id,
        x_L = x_L
      )
    })
  data_LOCF <- Reduce(merge, LOCF_values_by_variable)
  data_LOCF <-
    data_LOCF[match(unique(data_long[[individual_id]][data_long[[individual_id]] %in% data_LOCF[[individual_id]]]), data_LOCF[[individual_id]]), ]
  if (!is.na(cv_name)) {
    data_LOCF <-
      dplyr::left_join(data_LOCF, unique(data_long[c(individual_id, cv_name)]), by =
                         individual_id)
  }
  data_LOCF <-
    data_LOCF[, order(match(names(data_LOCF), names(data_long)))]
  data_LOCF <-
    data_LOCF[order(match(data_LOCF[[individual_id]], data_long[[individual_id]])), ]
  rownames(data_LOCF) <- NULL

  list(
    data_longitudinal = data_LOCF,
    model_longitudinal = "LOCF",
    call = call
  )
}

#' Fit a landmark model using a last observation carried forward (LOCF) method for the longitudinal data
#'
#' This function performs the two-stage landmarking analysis.
#'
#' @param data_long Data frame or list of data frames each corresponding to a landmark age `x_L` (each element of the list must be named the value of `x_L` it corresponds to).
#' Each data frame contains repeat measurements data and time-to-event data in long format.
#' @template x_L
#' @template x_hor
#' @template event_status
#' @template event_time
#' @param k Integer specifying the number of folds for cross-validation. An alternative to setting parameter `cross_validation_df` for performing cross-validation;
#' if both are missing no cross-validation is used.
#' @template cross_validation_df
#' @template b
#' @template covariates
#' @template covariates_time
#' @template individual_id
#' @template survival_submodel
#' @return List containing containing information about the landmark model at each of the landmark times.
#' Each element of this list is named the corresponding landmark time, and is itself a list containing elements:
#' `data`, `model_longitudinal`, `model_survival`, and `prediction_error`.
#'
#' `data`  has one row for each individual in the risk set at `x_L` and
#' contains the value of the `covariates` at the landmark time `x_L` using the LOCF approach. It also includes the predicted
#' probability that the event of interest has occurred by time \code{x_hor}, labelled as \code{"event_prediction"}.
#' There is one row for each individual.
#'
#' `model_longitudinal` indicates that the longitudinal approach is LOCF.
#'
#' `model_survival` contains the outputs from the function used to fit the survival submodel, including the estimated parameters of the model.
#' For a model using cross-validation, `model_survival` contains a list of outputs with each
#' element in the list corresponding to a different cross-validation fold. For more information on how the survival model is fitted
#' please see `?fit_survival_model` which is a function used within `fit_LOCF_landmark`.
#'
#' `prediction_error` contains a list indicating the c-index and Brier score at time `x_hor` and their standard errors if parameter `b` is used.
#' For more information on how the prediction error is calculated
#' please see `?get_model_assessment` which is the function used to do this within `fit_LOCF_landmark`.
#'
#' @details Firstly, this function selects the individuals in the risk set at the landmark time \code{x_L}.
#' Specifically, the individuals in the risk set are those that have entered the study before the landmark time \code{x_L}
#' (there is at least one observation for each of the \code{predictors_LME} and \code{random_effects} on or before \code{x_L}) and
#' exited the study after the landmark age (\code{event_time}
#' is greater than \code{x_L}).
#'
#' Secondly, if the option to use cross validation
#' is selected (using either parameter `k` or `cross_validation_df`), then an extra column `cross_validation_number` is added with the
#' cross-validation folds. If parameter `k` is used, then the function `add_cv_number`
#' randomly assigns these folds. For more details on this function see `?add_cv_number`.
#' If the parameter `cross_validation_df` is used, then the folds specified in this data frame are added.
#' If cross-validation is not selected then the landmark model is
#' fit to the entire group of individuals in the risk set (this is both the training and test dataset).
#'
#' Thirdly, the landmark model is then fit to each of the training datasets. There are two parts to fitting the landmark model: using the longitudinal data and using the survival data.
#' Using the longitudinal data is the first stage and is performed using `fit_LOCF_longitudinal`. See `?fit_LOCF_longitudinal` more for information about this function.
#' This function censors the
#' individuals at the time horizon `x_L` and fits the survival model. Using the survival data is the second stage and is performed using `fit_survival_model`. See `?fit_survival_model` more for information about this function.
#'
#' Fourthly, the performance of the model is then assessed on the set of predictions
#' from the entire set of individuals in the risk set by calculating Brier score and C-index.
#' This is performed using `get_model_assessment`. See `?get_model_assessment` more for information about this function.
#'
#' @author Isobel Barrott \email{isobel.barrott@@gmail.com}
#' @examples
#' library(Landmarking)
#' data(data_repeat_outcomes)
#' data_model_landmark_LOCF <-
#'    fit_LOCF_landmark(
#'      data_long = data_repeat_outcomes,
#'      x_L = c(60, 61),
#'      x_hor = c(65, 66),
#'      covariates =
#'        c("ethnicity", "smoking", "diabetes", "sbp_stnd", "tchdl_stnd"),
#'      covariates_time =
#'        c(rep("response_time_sbp_stnd", 4), "response_time_tchdl_stnd"),
#'      k = 10,
#'      individual_id = "id",
#'      event_time = "event_time",
#'      event_status = "event_status",
#'      survival_submodel = "cause_specific"
#'    )
#' @importFrom stats as.formula
#' @importFrom survival Surv
#' @importFrom survival coxph
#' @importFrom prodlim Hist
#' @export


fit_LOCF_landmark <- function(data_long,
                              x_L,
                              x_hor,
                              covariates,
                              covariates_time,
                              k,
                              cross_validation_df,
                              individual_id,
                              event_time,
                              event_status,
                              survival_submodel = c("standard_cox", "cause_specific", "fine_gray"),
                              b) {
  call <- match.call()

  survival_submodel <- match.arg(survival_submodel)

  #Checks
  if (missing(k)) {
    k_add <- FALSE
  }
  else{
    k_add <- TRUE
    if (!(is.numeric(k))) {
      stop("k should be numeric")
    }
  }

  if (missing(cross_validation_df)) {
    cross_validation_df_add <- FALSE
  }
  else{
    cross_validation_df_add <- TRUE
    if (inherits(cross_validation_df, "list")) {
      if (!all(x_L %in% names(cross_validation_df))) {
        stop(
          "The names of elements in cross_validation_df list should be the landmark times in x_L"
        )
      }
      if (any(Reduce("c", lapply(cross_validation_df, function(x) {
        any(duplicated(dplyr::distinct(x[, c(individual_id, "cross_validation_number")])[, individual_id]))
      })))) {
        stop("Cross validation folds should be the same for the same individual")
      }
    }
    else if (inherits(cross_validation_df,"data.frame")) {
      if (any(duplicated(dplyr::distinct(cross_validation_df[, c(individual_id, "cross_validation_number")])[, individual_id]))) {
        stop("Cross validation folds should be the same for the same individual")
      }
      cross_validation_df<-list(cross_validation_df)
      names(cross_validation_df)<-x_L
    }
    else{
      stop("cross_validation_df should be either a data frame or a list")
    }
  }
  if (k_add == TRUE &&
      cross_validation_df_add == TRUE) {
    stop("Either use parameter k or cross_validation_df but not both")
  }
  if (k_add == FALSE &&
      cross_validation_df_add == FALSE) {
    cv_name <- NA
  } else{
    cv_name <- "cross_validation_number"
  }

  if (!(length(covariates_time) %in% c(length(covariates), 1))) {
    stop("Length of covariates_time should be equal to length of covariates or 1")
  }
  if (length(covariates_time) == 1) {
    covariates_time <- rep(covariates_time, times = length(covariates))
  }

  if (length(x_L) != length(x_hor)) {
    stop("Length of x_L should be the same as length of x_hor")
  }
  if (!(is.data.frame(data_long) ||
        is.list(data_long))) {
    stop("data_long should be a list or data.frame")
  }
  if (is.data.frame(data_long)) {
    data_long <- lapply(x_L, function(x_l) {
      data_long
    })
    names(data_long) <- x_L
  }
  if (is.list(data_long)) {
    if (!setequal(names(data_long), x_L)) {
      stop("Names of elements in data_long should be landmark ages x_L")
    }
  }

  if (missing(b)) {
    b <- NA
  }
  #Find risk set
  data_long_x_L<-find_LOCF_risk_set(data_long=data_long,
                     x_L=x_L,
                     x_hor=x_hor,
                     covariates=covariates,
                     covariates_time=covariates_time,
                     individual_id=individual_id,
                     event_time=event_time,
                     event_status=event_status)

  #Add cross-validation folds
  if (cross_validation_df_add == TRUE) {
    for (x_l in x_L){
      data_long_x_L[[as.character(x_l)]]<-
        dplyr::left_join(data_long_x_L[[as.character(x_l)]], cross_validation_df[[as.character(x_l)]][,c(individual_id,"cross_validation_number")],by=individual_id)
    }
    if(any(is.na(data_long_x_L[[as.character(x_l)]][,"cross_validation_number"]))){stop("Cross validation number not defined for all in individual_id")}
  }

  if (k_add == TRUE) {
    data_long_x_L_cv <-
      add_cv_number(
        data_long = Reduce("rbind", data_long_x_L),
        individual_id = individual_id,
        k = k
      )
    data_long_x_L <-
      lapply(data_long_x_L, function(x) {
        dplyr::left_join(x, dplyr::distinct(data_long_x_L_cv[, c(individual_id, "cross_validation_number")]), by =
                           individual_id)
      })
  }

  #Fit each landmark model
  out <- lapply(1:length(x_L), function(i) {
    x_l <- x_L[i]
    x_h <- x_hor[i]

    data_long <- data_long_x_L[[as.character(x_l)]]

    message("Fitting longitudinal submodel, landmark age ", x_l)
    data_model_longitudinal <-
      fit_LOCF_longitudinal(
        data_long = data_long,
        x_L = x_l,
        covariates = covariates,
        covariates_time =
          covariates_time,
        cv_name = cv_name,
        individual_id =
          individual_id
      )

    message("Complete, landmark age ", x_l)

    data_events <-
      dplyr::distinct(data_long[, c(individual_id, event_status, event_time)])
    data_longitudinal <-
      dplyr::left_join(data_model_longitudinal$data_longitudinal,
                       data_events,
                       by = individual_id)

    message("Fitting survival submodel, landmark age ", x_l)
    data_model_survival <- fit_survival_model(
      data = data_longitudinal,
      individual_id = individual_id,
      cv_name = cv_name,
      covariates = covariates,
      event_time = event_time,
      event_status = event_status,
      survival_submodel = survival_submodel,
      x_hor = x_h
    )
    message("Complete, landmark age ", x_l)

    data_events <-
      dplyr::left_join(data_events,
                       data_model_survival$data_survival[,c(individual_id,"event_prediction")],
                       by = individual_id)

    prediction_error <-
      get_model_assessment(
        data = data_model_survival$data_survival,
        individual_id = individual_id,
        event_prediction = "event_prediction",
        event_status = event_status,
        event_time = event_time,
        x_hor = x_h,
        b = b
      )

    list(
      data = data_model_survival$data_survival,
      model_longitudinal = data_model_longitudinal$model_longitudinal,
      model_survival = data_model_survival$model_survival,
      prediction_error = prediction_error,
      call = call
    )
  })
  names(out) <- x_L
  class(out) <- "landmark"
  out
}
