import { copy } from "@/shared/i18n/id";

export function LeaderboardSection() {
  const leaderboard = copy.landing.leaderboard;

  return (
    <section className="landing-section landing-leaderboard" aria-labelledby="leaderboard-title">
      <div className="landing-leaderboard__heading">
        <p className="landing-eyebrow">{leaderboard.eyebrow}</p>
        <h2 id="leaderboard-title">{leaderboard.title}</h2>
        <p>{leaderboard.summary}</p>
      </div>
      <div className="landing-leaderboard__visual">
        <div
          aria-label={leaderboard.caption}
          className="landing-leaderboard__table-wrap"
          role="region"
          tabIndex={0}
        >
          <table>
            <caption className="visually-hidden">{leaderboard.caption}</caption>
            <thead>
              <tr>
                <th scope="col">{leaderboard.columns.rank}</th>
                <th scope="col">{leaderboard.columns.participant}</th>
                <th scope="col">{leaderboard.columns.progress}</th>
                <th scope="col">{leaderboard.columns.points}</th>
              </tr>
            </thead>
            <tbody>
              {leaderboard.rows.map((row) => (
                <tr key={row.rank}>
                  <th scope="row">{row.rank}</th>
                  <td>{row.participant}</td>
                  <td>
                    <span className="landing-leaderboard__progress">
                      <i style={{ inlineSize: `${row.progress}%` }} />
                      <span>{row.progress}%</span>
                    </span>
                  </td>
                  <td>{row.points}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <div aria-hidden="true" className="landing-podium">
          <span data-rank="2">2</span>
          <span data-rank="1">1</span>
          <span data-rank="3">3</span>
        </div>
      </div>
    </section>
  );
}
