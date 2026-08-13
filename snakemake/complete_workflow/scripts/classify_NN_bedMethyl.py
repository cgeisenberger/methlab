from NN_model import NN_classifier
import pandas as pd

NN = NN_classifier(str(snakemake.params["model"]))

predictions, class_labels, n_features = NN.predict_from_bedMethyl(snakemake.input["bed"])

# write predictions to table
df = pd.DataFrame({'class': class_labels, 'score': predictions, 'num_features': n_features})
df.to_csv(snakemake.output['votes'], sep='\t')

print(df)

# write summary to txt file
summary = ['Number of features: ' + str(n_features),
           'Predicted Class: ' + str(class_labels[0]),
           "Score: " + str(predictions[0])
          ]

with open(snakemake.output["txt"], 'w') as f:
  f.write("\n".join(summary))
