class Api::RelationsController < ApiController

  def index
    dataset = Dataset.find_by(visualization_id: params[:visualization_id])
    @relations = dataset.relations
                     .includes(:source, :target)
                     .order('nodes.name', 'targets_relations.name')
  end

  def types
    dataset = Dataset.find_by(visualization_id: params[:visualization_id])
    @relation_types = dataset.relations
                 .select(:relation_type)
                 .map(&:relation_type)
                 .reject(&:blank?)
                 .uniq
  end

  def show
    @relation = Relation.find(params[:id])
  end

  def create
    @relation = Relation.create(relation_params)
    render :show
  end

  def update
    @relation = Relation.update(params[:id], relation_params)
    render :show
  end

  def destroy
    Relation.destroy(params[:id])
    head :no_content
  end

  private

  def relation_params
    params.require(:relation).permit(:source_id, :target_id, :relation_type, :direction, :from, :to, :at, :dataset_id)
  end

end