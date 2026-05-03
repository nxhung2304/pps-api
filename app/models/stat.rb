class Stat < ApplicationRecord
  belongs_to :user

  validates :user_id, presence: true
  validates :date, presence: true, uniqueness: { scope: :user_id }
  validates :total_coding_time, :total_gym_time, :event_count,
            presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :total_run_distance, :sleep_duration,
            presence: true, numericality: { greater_than_or_equal_to: 0 }

  def self.increment_metrics(user_id, date, updates)
    return if updates.blank?

    updates = updates.symbolize_keys
    set_clauses = updates.keys.map { |k| "#{k} = stats.#{k} + EXCLUDED.#{k}" }
    set_clauses << "updated_at = EXCLUDED.updated_at"

    columns = [ :user_id, :date, :created_at, :updated_at ] + updates.keys
    values = [ user_id, date, Time.current, Time.current ] + updates.values

    sql = <<~SQL
      INSERT INTO stats (#{columns.join(', ')})
      VALUES (#{columns.size.times.map { '?' }.join(', ')})
      ON CONFLICT (user_id, date)
      DO UPDATE SET #{set_clauses.join(', ')}
    SQL

    connection.execute(sanitize_sql_array([ sql, *values ]))
  end
end
