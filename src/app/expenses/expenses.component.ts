import { Component, OnInit, ViewChild } from '@angular/core';
import { MatTableDataSource, MatSort } from '@angular/material';
import { ExpensesService } from '../services/expense.service';
import { UtilityService } from '../services/utility.service';
import { Expense } from '../models/expense.model';
import { CategoriesService } from '../services/categories.service';
import { PaymentMethodsService } from '../services/payment-methods.service';

@Component({
  selector: 'app-expenses',
  templateUrl: './expenses.component.html',
  styleUrls: ['./expenses.component.scss']
})
export class ExpensesComponent implements OnInit {
  displayedColumns: string[] = ['day', 'category.description', 'description', 'value', 'paymentMethod.description', 'edit', 'remove'];
  dataSource: MatTableDataSource<Expense>;
  @ViewChild(MatSort) sort: MatSort;

  expenses: Expense[];

  constructor(
    private util: UtilityService,
    private expensesService: ExpensesService,
    private categoriesService: CategoriesService,
    private paymentMethodsService: PaymentMethodsService) { }

  ngOnInit() {
    this.getExpenses();
  }

  nestedFilterCheck(search, data, key) {
    if (typeof data[key] === 'object') {
      for (const k in data[key]) {
        if (data[key][k] !== null) {
          search = this.nestedFilterCheck(search, data[key], k);
        }
      }
    } else {
      search += data[key];
    }
    return search;
  }

  applyFilter(filterValue: string) {
    this.dataSource.filter = filterValue.trim().toLowerCase();
  }

  getExpenses() {
    this.util.showLoading();
    this.expensesService.getAllWithQuery((x => x.orderBy('day', 'desc')))
      .subscribe(data => {
        this.expenses = data;
        this.expenses.forEach((expense) => {
          this.categoriesService.get(expense.idCategory).subscribe(data => {
            expense.category = data;
            this.paymentMethodsService.get(expense.idPaymentMethod).subscribe(data => {
              expense.paymentMethod = data;
              debugger;
              this.dataSource = new MatTableDataSource(this.expenses);
              this.dataSource.sort = this.sort;

              this.dataSource.filterPredicate = (data, filter: string) => {
                const accumulator = (currentTerm, key) => {
                  return this.nestedFilterCheck(currentTerm, data, key);
                };
                const dataStr = Object.keys(data).reduce(accumulator, '').toLowerCase();
                // Transform the filter by converting it to lowercase and removing whitespace.
                const transformedFilter = filter.trim().toLowerCase();
                return dataStr.indexOf(transformedFilter) !== -1;
              };

              this.util.hideLoading();
            });
          });
        })

      }, err => {
        this.util.hideLoading();
      });
  }

  getTotalCost() {
    if (this.expenses != null) {
      return this.expenses.map(t => t.value).reduce((acc, value) => acc + value, 0);
    }

    return '';
  }

  getCategory(idCategory: string) {
    return this.categoriesService.get(idCategory).subscribe(data => {
      return data;
    });
  }

  removeExpense(id: string) {
    this.util.showLoading();
    this.expensesService
      .remove(id)
      .catch(() => {
      })
      .finally(() => {
        this.util.hideLoading();
      });
  }
}
