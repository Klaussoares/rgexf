% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/math.R
\name{switch.edges}
\alias{switch.edges}
\title{Switches between source and target}
\usage{
switch.edges(edges)
}
\arguments{
\item{edges}{A matrix or data frame structured as a list of edges}
}
\value{
A list containing two data frames.
}
\description{
Puts the lowest id node among every dyad as source (and the other as target)
}
\details{
\code{edge.list} transforms the input into a two-elements list containing a
dataframe of nodes (with columns \dQuote{id} and \dQuote{label}) and a
dataframe of edges. The last one is numeric (with columns \dQuote{source}
and \dQuote{target}) and based on auto-generated nodes' ids.
}
\examples{

  relations <- cbind(c(1,1,3,4,2,5,6), c(2,3,1,2,4,1,1))
  relations
  
  switch.edges(relations)
}
\seealso{
Other manipulation: 
\code{\link{check.dpl.edges}()}
}
\author{
George Vega Yon
}
\concept{manipulation}
\keyword{manip}
